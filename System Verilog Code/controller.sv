
// CONTROLLER  (Main Decoder + ALU Decoder)
// Harris & Harris Ch.7
/*`include"maindecoder.v"
`include"ALUdecoder.v"*/
//  Pipelined control unit — Harris & Harris Ch.7, Fig 7.61
//
//  The controller is purely combinational. It decodes the
//  Decode-stage instruction (op, funct3, funct7b5) and
//  produces all control signals.  These are pipelined through
//  the D/E/M/W pipeline registers in the datapath.
//
//  PCSrcE (= BranchE & ZeroE | JumpE) is computed inside the
//  datapath Execute stage and is NOT routed back here.

module controller (
    // D-stage instruction fields
    input  logic [6:0] opD,
    input  logic [2:0] funct3D,
    input  logic       funct7b5D,
    // D-stage control outputs → pipeline registers in datapath
    output logic       RegWriteD,
    output logic [1:0] ResultSrcD,
    output logic       MemWriteD,
    output logic       JumpD,
    output logic       BranchD,
    output logic [2:0] ALUControlD,
    output logic       ALUSrcD,
    output logic [1:0] ImmSrcD
);
    logic [1:0] ALUOpD;

    maindec md (
        .op       (opD),
        .ResultSrc(ResultSrcD), .MemWrite(MemWriteD),
        .Branch   (BranchD),    .ALUSrc  (ALUSrcD),
        .RegWrite (RegWriteD),  .Jump    (JumpD),
        .ImmSrc   (ImmSrcD),   .ALUOp   (ALUOpD)
    );

    aludec ad (
        .opb5     (opD[5]),
        .funct3   (funct3D),
        .funct7b5 (funct7b5D),
        .ALUOp    (ALUOpD),
        .ALUControl(ALUControlD)
    );
endmodule
