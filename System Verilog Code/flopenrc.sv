
//  flopenrc.sv — flip-flop with enable AND synchronous clear
//  Used for F/D pipeline register (stall + flush)

module flopenrc #(parameter WIDTH = 32) (
    input  logic             clk, reset, en, clear,
    input  logic [WIDTH-1:0] d,
    output logic [WIDTH-1:0] q
);
    always_ff @(posedge clk or posedge reset)
        if (reset)       q <= '0;
        else if (clear)  q <= '0;
        else if (en)     q <= d;
endmodule
