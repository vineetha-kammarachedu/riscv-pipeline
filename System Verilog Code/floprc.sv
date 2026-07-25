//  floprc.sv — flip-flop with reset AND synchronous clear
//  Used for D/E pipeline register (bubble insertion)

module floprc #(parameter WIDTH = 32) (
    input  logic             clk, reset, clear,
    input  logic [WIDTH-1:0] d,
    output logic [WIDTH-1:0] q
);
    always_ff @(posedge clk or posedge reset)
        if (reset | clear) q <= '0;
        else               q <= d;
endmodule
