
//  hazard.sv
//  Hazard Unit — Harris & Harris Ch.7, Figure 7.61
//
//  Handles three categories of hazard:
//
//  1. DATA HAZARD — forwarding (EX/MEM or MEM/WB → EX)
//     ForwardAE / ForwardBE:
//       10 = forward from Memory  stage (ALUResultM)
//       01 = forward from Writeback stage (ResultW)
//       00 = use register-file output (no hazard)
//     MEM priority over WB (more recent instruction wins).
//     x0 is never forwarded.
//
//  2. LOAD-USE STALL (lw followed immediately by dependent instr)
//     Detected when:
//       ResultSrcE[0] == 1  (load is in Execute stage)
//       AND RdE matches Rs1D or Rs2D
//     Response: StallF, StallD, FlushE
//
//  3. CONTROL HAZARD — branch / jal flush
//     Detected when PCSrcE == 1 (branch taken or jal)
//     Response: FlushD, FlushE
//
//  Combined flush logic (textbook p. 451):
//    lwStall = ResultSrcE0 & ((Rs1D==RdE)|(Rs2D==RdE))
//    StallF  = lwStall
//    StallD  = lwStall
//    FlushD  = PCSrcE
//    FlushE  = lwStall | PCSrcE

module hazard (
    // Forwarding inputs
    input  logic [4:0] Rs1E, Rs2E,        // E-stage source regs
    input  logic [4:0] RdM,  RdW,         // M/W-stage dest regs
    input  logic       RegWriteM, RegWriteW,
    // Stall inputs
    input  logic       ResultSrcE0,        // bit[0] of ResultSrcE → lw
    input  logic [4:0] Rs1D, Rs2D,        // D-stage source regs
    input  logic [4:0] RdE,               // E-stage dest reg
    // Branch/jump decision
    input  logic       PCSrcE,
    // Outputs
    output logic [1:0] ForwardAE, ForwardBE,
    output logic       StallF, StallD,
    output logic       FlushD, FlushE
);
    logic lwStall;

    // Forwarding logic 
    always_comb begin
        // ForwardAE: choose source for ALU operand A
        if      ((Rs1E == RdM) & RegWriteM & (Rs1E != 5'b0))
            ForwardAE = 2'b10;   // forward from MEM stage
        else if ((Rs1E == RdW) & RegWriteW & (Rs1E != 5'b0))
            ForwardAE = 2'b01;   // forward from WB  stage
        else
            ForwardAE = 2'b00;   // use register file

        // ForwardBE: choose source for ALU operand B (before ALUSrc mux)
        if      ((Rs2E == RdM) & RegWriteM & (Rs2E != 5'b0))
            ForwardBE = 2'b10;
        else if ((Rs2E == RdW) & RegWriteW & (Rs2E != 5'b0))
            ForwardBE = 2'b01;
        else
            ForwardBE = 2'b00;
    end

    // Load-use stall 
    assign lwStall = ResultSrcE0 & ((Rs1D == RdE) | (Rs2D == RdE));

    assign StallF = lwStall;
    assign StallD = lwStall;

    // Flush signals 
    assign FlushD = PCSrcE;
    assign FlushE = lwStall | PCSrcE;
endmodule
