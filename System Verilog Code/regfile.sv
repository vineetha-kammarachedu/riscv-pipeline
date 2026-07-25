
//  32 × 32-bit register file
//  Harris & Harris Ch.7
//
//  x0 is hardwired to 0.
//  Write: synchronous, rising edge
//  Read:  combinational with write-through bypass
//
//  Write-through: when WB writes a register that Decode reads
//  in the same cycle, the read port returns the new write data.
//  This implements the textbook's "write first half / read
//  second half of the cycle" behaviour (p.752 H&H) in RTL.

module regfile (
    input  logic        clk,
    input  logic        we3,
    input  logic [4:0]  a1, a2, a3,
    input  logic [31:0] wd3,
    output logic [31:0] rd1, rd2
);
    logic [31:0] rf [31:0];

    // Initialise all registers to 0 for clean simulation
    integer i;
    initial for (i = 0; i < 32; i = i+1) rf[i] = '0;

    // Synchronous write; x0 is never overwritten
    always_ff @(posedge clk)
        if (we3 && a3 != '0) rf[a3] <= wd3;

    // Combinational read with write-through on x1–x31
    assign rd1 = (a1 == '0) ? '0 :
                 (we3 && a3 == a1) ? wd3 : rf[a1];
    assign rd2 = (a2 == '0) ? '0 :
                 (we3 && a3 == a2) ? wd3 : rf[a2];
endmodule
