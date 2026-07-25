
//  32-bit ALU — Harris & Harris Ch.7
//  ALUControl: 000=ADD  001=SUB  010=AND  011=OR  101=SLT

module alu (
    input  logic [31:0] a, b,
    input  logic [2:0]  ALUControl,
    output logic [31:0] ALUResult,
    output logic        Zero
);
    logic [31:0] condinvb, sum;

    assign condinvb = ALUControl[0] ? ~b : b;
    assign sum      = a + condinvb + {31'b0, ALUControl[0]};

    always_comb
        case (ALUControl)
        3'b000, 3'b001: ALUResult = sum;              // ADD / SUB
        3'b010:         ALUResult = a & b;             // AND
        3'b011:         ALUResult = a | b;             // OR
        3'b101:         ALUResult = {31'b0, sum[31]};  // SLT (signed)
        default:        ALUResult = '0;
        endcase

    assign Zero = (ALUResult == '0);
endmodule
