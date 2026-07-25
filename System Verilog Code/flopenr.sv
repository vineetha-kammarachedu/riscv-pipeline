
//  flopenr.sv — flip-flop with enable (no clear)
//  Used for PC register (stall = hold)

module flopenr #(parameter WIDTH = 32) (
    input  logic             clk, reset, en,
    input  logic [WIDTH-1:0] d,
    output logic [WIDTH-1:0] q
);
    always_ff @(posedge clk or posedge reset)
        if (reset)   q <= '0;
        else if (en) q <= d;
endmodule
