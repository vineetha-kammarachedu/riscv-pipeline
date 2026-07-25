//  tb_riscv_pipeline.sv
//  Self-checking testbench for the 5-stage pipelined RISC-V
//  Harris & Harris Ch.7
//
//  Test program: riscvtest.mem  (same program used for the
//  single-cycle testbench, Harris Fig. 7.64)
//
//  The program exercises: addi, or, and, add, beq (not-taken),
//  slt, beq (taken, control hazard + 2 flushes),
//  slt, add, sub, sw, lw (load-use stall), add, jal, add, sw
//
//  Key hazards exercised:
//    EX-EX forwarding   : back-to-back ALU instructions
//    MEM-EX forwarding  : result used 2 instructions later
//    Load-use stall     : lw immediately followed by dependent add
//    Branch flush       : beq taken → 2 pipeline stages flushed
//    JAL flush          : unconditional jump → 2 stages flushed
//
//  Success condition: mem[100] = 25  (same as single-cycle TB)

`timescale 1ns/1ps

//`include"top.v"
module tb_riscv_pipeline;

    //DUT signals 
    logic        clk, reset;
    logic [31:0] WriteDataM, DataAdrM;
    logic        MemWriteM;

    // DUT 
    top dut (
        .clk       (clk),
        .reset     (reset),
        .WriteDataM(WriteDataM),
        .DataAdrM  (DataAdrM),
        .MemWriteM (MemWriteM)
    );

    //  Clock: 10 ns period 
    initial  clk = 0;
    always  #5 clk = ~clk;

    // Reset: 2 cycles 
    initial begin
        reset = 1;
        @(posedge clk); #1;
        @(posedge clk); #1;
        reset = 0;
    end

    // Timeout guard 
    initial begin
        #20_000;
        $display("TIMEOUT — did not complete in 20 000 ns");
        $finish;
    end

    //  Cycle trace 
    // Shows Fetch PC, any store address/data, stall and flush signals
    always @(negedge clk) begin
        if (!reset)
            $display(
                "t=%4t  PCF=%08h  DataAdr=%4d  WData=%4d  MemWr=%b  StallF=%b StallD=%b FlushD=%b FlushE=%b",
                $time,
                dut.cpu.dp.PCF,
                DataAdrM, WriteDataM, MemWriteM,
                dut.cpu.dp.StallF,
                dut.cpu.dp.StallD,
                dut.cpu.dp.FlushD,
                dut.cpu.dp.FlushE);
    end

    //Self-check 
    // Sample every negedge when a store is committed.
    // Success : DataAdrM=100, WriteDataM=25
    // Progress: DataAdrM=96  (intermediate sw)
    // Failure : anything else
    always @(negedge clk) begin
        if (MemWriteM) begin
            if (DataAdrM === 32'd100 && WriteDataM === 32'd25) begin
                $display("");
               
              $display("  Simulation PASSED    mem[100] = 25    ");
             
                $display("");
                $finish;
            end else if (DataAdrM !== 32'd96) begin
                $display("");
              
                $display(" Simulation FAILED                                ");
                $display("  Expected : DataAdrM=100, WriteDataM=25          ");
                $display("  Got      : DataAdrM=%0d, WriteDataM=%0d         ",
                         DataAdrM, WriteDataM);
               
                $finish;
            end
        end
    end

endmodule
