
//  maindec.sv
//  Main control decoder
//  Harris & Harris Ch.7, Table 7.6
//
//  Control word (11 bits):
//  {RegWrite, ImmSrc[1:0], ALUSrc, MemWrite,
//   ResultSrc[1:0], Branch, ALUOp[1:0], Jump}
//
//  Supported instructions:
//   lw   (I-type load)
//   sw   (S-type store)
//   R-type (add, sub, and, or, slt)
//   beq  (B-type branch)
//   I-type ALU (addi, andi, ori, slti)
//   jal  (J-type jump)

module maindec (
    input  logic [6:0] op,
    output logic [1:0] ResultSrc,
    output logic       MemWrite,
    output logic       Branch, ALUSrc,
    output logic       RegWrite, Jump,
    output logic [1:0] ImmSrc,
    output logic [1:0] ALUOp
);
    logic [10:0] controls;

    // Unpack control word
    assign {RegWrite, ImmSrc, ALUSrc, MemWrite,
            ResultSrc, Branch, ALUOp, Jump} = controls;

    always_comb
        case (op)
        //                         Rw Im  As Mw Rs  Br AU Jp
        7'b0000011: controls = 11'b1_00_1_0_01_0_00_0; // lw
        7'b0100011: controls = 11'b0_01_1_1_00_0_00_0; // sw
        7'b0110011: controls = 11'b1_xx_0_0_00_0_10_0; // R-type
        7'b1100011: controls = 11'b0_10_0_0_00_1_01_0; // beq
        7'b0010011: controls = 11'b1_00_1_0_00_0_10_0; // I-type ALU
        7'b1101111: controls = 11'b1_11_0_0_10_0_00_1; // jal
        default:    controls = 11'b0_00_0_0_00_0_00_0; // safe NOP
        endcase
endmodule
