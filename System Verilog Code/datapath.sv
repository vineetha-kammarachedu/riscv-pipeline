
// DATAPATH
// Harris & Harris Ch.7 — Single-Cycle RISC-V
/*`include"flopr.v"
`include"adder.v"
`include"mux2.v"
`include"regfile.v"
`include"extend.v"
`include"alu.v"
`include"mux3.v"
`include"hazard.sv"*/
//  5-stage pipelined datapath
//  Harris & Harris Ch.7, Figure 7.61
//
//  Stage boundaries (pipeline registers):
//    F → D : flopenrc  (enable + sync-clear)
//    D → E : floprc    (sync-clear only)
//    E → M : flopr     (plain reset)
//    M → W : flopr     (plain reset)
//
//  All pipeline registers are in ONE always_ff block
//  so that NBA scheduling guarantees the E→M stage reads
//  pre-clock values of RdE etc. even though D→E writes
//  those signals in the same block.

module datapath (
    input  logic        clk, reset,

    //  Fetch 
    output logic [31:0] PCF,
    input  logic [31:0] InstrF,

    //  D-stage control inputs (from controller)
    input  logic        RegWriteD,
    input  logic [1:0]  ResultSrcD,
    input  logic        MemWriteD, JumpD, BranchD, ALUSrcD,
    input  logic [2:0]  ALUControlD,
    input  logic [1:0]  ImmSrcD,

    //  D-stage instruction fields back to controller 
    output logic [6:0]  opD,
    output logic [2:0]  funct3D,
    output logic        funct7b5D,

    // Hazard / branch feedback 
    output logic        ZeroE,
    output logic        PCSrcE,

    //  Memory interface 
    output logic        MemWriteM,
    output logic [31:0] DataAdrM, WriteDataM,
    input  logic [31:0] ReadDataM
);

    
    //  F/D PIPELINE REGISTERS
   
    logic [31:0] InstrD, PCD, PCPlus4D;

   
    //  D/E PIPELINE REGISTERS
  
    logic        RegWriteE, MemWriteE, JumpE, BranchE, ALUSrcE;
    logic [1:0]  ResultSrcE;
    logic [2:0]  ALUControlE;
    logic [31:0] RD1E, RD2E, PCE, ImmExtE, PCPlus4E;
    logic [4:0]  Rs1E, Rs2E, RdE;

   
    //  E/M PIPELINE REGISTERS
  
    logic        RegWriteM_r;
    logic [1:0]  ResultSrcM;
    logic [31:0] ALUResultM, WriteDataM_r, PCPlus4M;
    logic [4:0]  RdM;
    logic        MemWriteM_r;


    //  M/W PIPELINE REGISTERS
    
    logic        RegWriteW;
    logic [1:0]  ResultSrcW;
    logic [31:0] ALUResultW, ReadDataW, PCPlus4W;
    logic [4:0]  RdW;

   
    //  COMBINATIONAL WIRES
   
    logic [31:0] PCNextF, PCPlus4F;
    logic [31:0] RD1D, RD2D, ImmExtD;
    logic [31:0] SrcAE, SrcBE_fwd, SrcBE;
    logic [31:0] ALUResultE_w, PCTargetE;
    logic [31:0] ResultW;
    logic [1:0]  ForwardAE, ForwardBE;
    logic        StallF, StallD, FlushD, FlushE;

   
    //  FETCH STAGE
   
    adder         pcadd4      (PCF, 32'd4, PCPlus4F);
    assign PCSrcE = (BranchE & ZeroE) | JumpE;
    mux2 #(32)   pcmux       (PCPlus4F, PCTargetE, PCSrcE, PCNextF);

   
    //  DECODE STAGE
    
    assign opD      = InstrD[6:0];
    assign funct3D  = InstrD[14:12];
    assign funct7b5D = InstrD[30];

    // Register file — written in WB, read in D
    // Write-through: if WB writes the same reg being read, return new value.
    // This models Harris's "first-half write / second-half read" (p.752).
    regfile rf (
        .clk(clk),
        .we3(RegWriteW), .a3(RdW), .wd3(ResultW),
        .a1(InstrD[19:15]), .rd1(RD1D),
        .a2(InstrD[24:20]), .rd2(RD2D)
    );

    extend ext (.instr(InstrD[31:7]), .immsrc(ImmSrcD), .immext(ImmExtD));

   
    //  EXECUTE STAGE
  
    // Forwarding muxes (Fig 7.61):
    //   00 → reg-file output
    //   01 → ResultW  (from WB)
    //   10 → ALUResultM (from MEM)
    mux3 #(32) fwdAmux (RD1E,      ResultW, ALUResultM, ForwardAE, SrcAE);
    mux3 #(32) fwdBmux (RD2E,      ResultW, ALUResultM, ForwardBE, SrcBE_fwd);
    // ALUSrc selects between forwarded RF value and sign-extended immediate
    mux2 #(32) srcbmux (SrcBE_fwd, ImmExtE, ALUSrcE,               SrcBE);

    alu alu (
        .a(SrcAE), .b(SrcBE),
        .ALUControl(ALUControlE),
        .ALUResult(ALUResultE_w), .Zero(ZeroE)
    );

    // Branch / JAL target: PC_E + ImmExt_E
    adder branchadd (PCE, ImmExtE, PCTargetE);

    //  MEMORY STAGE outputs
   
    assign DataAdrM   = ALUResultM;
    assign WriteDataM = WriteDataM_r;
    assign MemWriteM  = MemWriteM_r;

    
    //  WRITEBACK STAGE
   
    // ResultSrc (Fig 7.61):
    //   00 → ALU result
    //   01 → data memory read (lw)
    //   10 → PC+4             (jal return address)
    mux3 #(32) resultmux (ALUResultW, ReadDataW, PCPlus4W,
                           ResultSrcW, ResultW);

    
    //  HAZARD UNIT (instantiated inside datapath to share all signals)
    
    hazard hu (
        .Rs1E(Rs1E),          .Rs2E(Rs2E),
        .RdM(RdM),            .RdW(RdW),
        .RegWriteM(RegWriteM_r), .RegWriteW(RegWriteW),
        .ResultSrcE0(ResultSrcE[0]),
        .Rs1D(InstrD[19:15]), .Rs2D(InstrD[24:20]),
        .RdE(RdE),
        .PCSrcE(PCSrcE),
        .ForwardAE(ForwardAE), .ForwardBE(ForwardBE),
        .StallF(StallF),      .StallD(StallD),
        .FlushD(FlushD),      .FlushE(FlushE)
    );

   
    //  ALL PIPELINE REGISTERS — ONE always_ff BLOCK
    //
    //  Reason: SystemVerilog NBA semantics guarantee that every LHS
    //  is read at pre-clock time within a single always_ff, so the
    //  E→M assignments (e.g. RdM <= RdE) see the OLD RdE value
    //  even though D→E (RdE <= InstrD[11:7]) is in the same block.
    //  Splitting across multiple always_ff blocks can cause
    //  simulator-dependent race conditions.
   
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            // PC
            PCF          <= '0;
            // F/D
            InstrD       <= '0;  PCD      <= '0;  PCPlus4D  <= '0;
            // D/E 
            RegWriteE    <= '0;  ResultSrcE <= '0; MemWriteE <= '0;
            JumpE        <= '0;  BranchE  <= '0;  ALUControlE <= '0;
            ALUSrcE      <= '0;  RD1E     <= '0;  RD2E      <= '0;
            PCE          <= '0;  ImmExtE  <= '0;  PCPlus4E  <= '0;
            Rs1E         <= '0;  Rs2E     <= '0;  RdE       <= '0;
            //  E/M
            RegWriteM_r  <= '0;  ResultSrcM <= '0; MemWriteM_r <= '0;
            ALUResultM   <= '0;  WriteDataM_r <= '0; PCPlus4M <= '0;
            RdM          <= '0;
            //  M/W 
            RegWriteW    <= '0;  ResultSrcW <= '0;
            ALUResultW   <= '0;  ReadDataW  <= '0;  PCPlus4W  <= '0;
            RdW          <= '0;
        end else begin

            //  PC (enable = ~StallF) 
            if (!StallF)  PCF <= PCNextF;

            //  F → D  (enable = ~StallD, clear = FlushD) 
            if      (FlushD)  begin
                InstrD   <= '0; PCD <= '0; PCPlus4D <= '0;
            end else if (!StallD) begin
                InstrD   <= InstrF;
                PCD      <= PCF;
                PCPlus4D <= PCPlus4F;
            end
            // else: StallD=1, FlushD=0 → hold (no change)

            //  D → E  (clear = FlushE, inserts bubble) 
            if (FlushE) begin
                RegWriteE   <= '0;  ResultSrcE  <= '0;  MemWriteE   <= '0;
                JumpE       <= '0;  BranchE     <= '0;  ALUControlE <= '0;
                ALUSrcE     <= '0;  RD1E        <= '0;  RD2E        <= '0;
                PCE         <= '0;  ImmExtE     <= '0;  PCPlus4E    <= '0;
                Rs1E        <= '0;  Rs2E        <= '0;  RdE         <= '0;
            end else begin
                RegWriteE   <= RegWriteD;
                ResultSrcE  <= ResultSrcD;
                MemWriteE   <= MemWriteD;
                JumpE       <= JumpD;
                BranchE     <= BranchD;
                ALUControlE <= ALUControlD;
                ALUSrcE     <= ALUSrcD;
                RD1E        <= RD1D;
                RD2E        <= RD2D;
                PCE         <= PCD;
                ImmExtE     <= ImmExtD;
                PCPlus4E    <= PCPlus4D;
                Rs1E        <= InstrD[19:15];
                Rs2E        <= InstrD[24:20];
                RdE         <= InstrD[11:7];
            end

            //  E → M  (always advances; reads pre-clock E values) 
            RegWriteM_r  <= RegWriteE;
            ResultSrcM   <= ResultSrcE;
            MemWriteM_r  <= MemWriteE;
            ALUResultM   <= ALUResultE_w;
            WriteDataM_r <= SrcBE_fwd;     // unforwarded Rs2 for store data
            PCPlus4M     <= PCPlus4E;
            RdM          <= RdE;

            // M → W
            RegWriteW  <= RegWriteM_r;
            ResultSrcW <= ResultSrcM;
            ALUResultW <= ALUResultM;
            ReadDataW  <= ReadDataM;
            PCPlus4W   <= PCPlus4M;
            RdW        <= RdM;
        end
    end
endmodule
