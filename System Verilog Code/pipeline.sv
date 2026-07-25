//  riscv.sv
//  Top-level RISC-V processor
//  Connects controller ↔ pipelined datapath
//  Harris & Harris Ch.7, Figure 7.61
/*`include"controller.v"
`include"datapath.v"*/
module riscv (
    input  logic        clk, reset,
    output logic [31:0] PCF,
    input  logic [31:0] InstrF,
    output logic        MemWriteM,
    output logic [31:0] DataAdrM, WriteDataM,
    input  logic [31:0] ReadDataM
);
    // D-stage control signals
    logic        RegWriteD, MemWriteD, JumpD, BranchD, ALUSrcD;
    logic [1:0]  ResultSrcD, ImmSrcD;
    logic [2:0]  ALUControlD;

    // D-stage instruction fields (datapath → controller)
    logic [6:0]  opD;
    logic [2:0]  funct3D;
    logic        funct7b5D;

    controller ctrl (
        .opD(opD), .funct3D(funct3D), .funct7b5D(funct7b5D),
        .RegWriteD(RegWriteD), .ResultSrcD(ResultSrcD),
        .MemWriteD(MemWriteD), .JumpD(JumpD),  .BranchD(BranchD),
        .ALUControlD(ALUControlD), .ALUSrcD(ALUSrcD),
        .ImmSrcD(ImmSrcD)
    );

    datapath dp (
        .clk(clk), .reset(reset),
        // Instruction memory
        .PCF(PCF), .InstrF(InstrF),
        // Control inputs from controller
        .RegWriteD(RegWriteD), .ResultSrcD(ResultSrcD),
        .MemWriteD(MemWriteD), .JumpD(JumpD),  .BranchD(BranchD),
        .ALUControlD(ALUControlD), .ALUSrcD(ALUSrcD),
        .ImmSrcD(ImmSrcD),
        // Instruction fields back to controller
        .opD(opD), .funct3D(funct3D), .funct7b5D(funct7b5D),
        // Data memory
        .MemWriteM(MemWriteM),
        .DataAdrM(DataAdrM), .WriteDataM(WriteDataM),
        .ReadDataM(ReadDataM)
    );
endmodule
