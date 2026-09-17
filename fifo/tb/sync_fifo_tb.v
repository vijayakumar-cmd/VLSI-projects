`timescale 1ns/1ps

module sync_fifo_tb;
    localparam integer W = 8;
    localparam integer D = 4;
    reg clk = 0, rst = 1, wr_en = 0, rd_en = 0;
    reg [W-1:0] din;
    wire [W-1:0] dout;
    wire full, empty;
    wire [$clog2(D+1)-1:0] count;
    integer errors = 0;

    always #5 clk = ~clk;
    sync_fifo #(.DATA_WIDTH(W), .DEPTH(D)) dut (.*);

    task write_word(input [W-1:0] value);
        begin @(negedge clk); din = value; wr_en = 1; @(negedge clk); wr_en = 0; end
    endtask
    task read_word(input [W-1:0] expected);
        begin
            @(negedge clk); rd_en = 1;
            @(posedge clk); #1;
            if (dout !== expected) begin $display("FAIL: expected %h got %h", expected, dout); errors = errors + 1; end
            @(negedge clk); rd_en = 0;
        end
    endtask

    initial begin
        din = 0;
        repeat (2) @(posedge clk); rst = 0;
        write_word(8'h11); write_word(8'h22); write_word(8'h33); write_word(8'h44);
        @(posedge clk); #1 if (!full) begin $display("FAIL: FIFO did not become full"); errors = errors + 1; end
        write_word(8'hFF);
        read_word(8'h11); read_word(8'h22); read_word(8'h33); read_word(8'h44);
        @(posedge clk); #1 if (!empty) begin $display("FAIL: FIFO did not become empty"); errors = errors + 1; end
        if (errors == 0) $display("PASS: synchronous FIFO test completed");
        else $display("FAIL: synchronous FIFO had %0d error(s)", errors);
        $finish;
    end
endmodule
