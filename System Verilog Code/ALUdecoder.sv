
//  aludec.sv
//  ALU control decoder
//  Harris & Harris Ch.7, Table 7.4
//
//  ALUControl encoding:
//   000 = ADD    001 = SUB
//   010 = AND    011 = OR     101 = SLT

module aludec (
    input  logic       opb5,      // op[5]: 1 for R-type / I-type
    input  logic [2:0] funct3,
    input  logic       funct7b5,  // distinguishes ADD vs SUB
    input  logic [1:0] ALUOp,
    output logic [2:0] ALUControl
);
    logic RtypeSub;
    assign RtypeSub = funct7b5 & opb5;   // SUB = R-type with funct7[5]=1

    always_comb
        case (ALUOp)
        2'b00: ALUControl = 3'b000;     // ADD (lw / sw address)
        2'b01: ALUControl = 3'b001;     // SUB (beq comparison)
        default:                          // R-type or I-type ALU
            case (funct3)
            3'b000: ALUControl = RtypeSub ? 3'b001 : 3'b000; // sub or add/addi
            3'b010: ALUControl = 3'b101; // slt / slti
            3'b110: ALUControl = 3'b011; // or  / ori
            3'b111: ALUControl = 3'b010; // and / andi
            default: ALUControl = 3'b000;
            endcase
        endcase
endmodule
