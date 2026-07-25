
//  Instruction memory — 256 × 32-bit ROM
//  Word-addressed: rd = RAM[a[31:2]]
//  Expanded to 256 words to hold larger test programs.

module imem (
    input  logic [31:0] a,
    output logic [31:0] rd
);
    logic [31:0] RAM [0:255];
    initial $readmemh("riscvtest.mem", RAM, 0, 255);
    assign rd = RAM[a[31:2]];
endmodule
