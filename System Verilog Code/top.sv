

/*`include"pipeline.v"
`include"imem.v"
`include"dmem.v"*/

//  top.sv
//  Top-level wrapper: RISC-V pipeline + imem + dmem
//  Harris & Harris Ch.7, Figure 7.61

module top (
    input  logic        clk, reset,
    // Expose memory-stage bus so the testbench can monitor stores
    output logic [31:0] WriteDataM, DataAdrM,
    output logic        MemWriteM
);
    logic [31:0] PCF, InstrF, ReadDataM;

    riscv   cpu  (.clk(clk), .reset(reset),
                  .PCF(PCF), .InstrF(InstrF),
                  .MemWriteM(MemWriteM),
                  .DataAdrM(DataAdrM), .WriteDataM(WriteDataM),
                  .ReadDataM(ReadDataM));
    imem    imem (.a(PCF),   .rd(InstrF));
    dmem    dmem (.clk(clk), .we(MemWriteM),
                  .a(DataAdrM), .wd(WriteDataM), .rd(ReadDataM));
endmodule
