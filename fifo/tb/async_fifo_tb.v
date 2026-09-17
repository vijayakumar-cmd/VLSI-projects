`timescale 1ns/1ps

module async_fifo_tb;
    localparam integer W = 8;
    localparam integer AW = 2;
    reg wr_clk = 0, rd_clk = 0, wr_rst_n = 0, rd_rst_n = 0;
    reg wr_en = 0, rd_en = 0;
    reg [W-1:0] din;
    wire [W-1:0] dout;
    wire full, empty;
    wire [AW:0] wr_level, rd_level;
    integer errors = 0;

    always #5 wr_clk = ~wr_clk;
    always #7 rd_clk = ~rd_clk;
    async_fifo #(.DATA_WIDTH(W), .ADDR_WIDTH(AW)) dut (.*);

    initial begin
        din = 0;
        repeat (3) @(posedge wr_clk); wr_rst_n = 1; rd_rst_n = 1;
        write_word(8'hA1); write_word(8'hB2); write_word(8'hC3); write_word(8'hD4);
        repeat (4) @(posedge rd_clk);
        read_word(8'hA1); read_word(8'hB2); read_word(8'hC3); read_word(8'hD4);
        repeat (5) @(posedge rd_clk);
        if (!empty) begin $display("FAIL: async FIFO did not become empty"); errors = errors + 1; end
        if (errors == 0) $display("PASS: asynchronous FIFO test completed");
        else $display("FAIL: asynchronous FIFO had %0d error(s)", errors);
        $finish;
    end

    task write_word(input [W-1:0] value);
        begin @(negedge wr_clk); din = value; wr_en = 1; @(negedge wr_clk); wr_en = 0; end
    endtask
    task read_word(input [W-1:0] expected);
        begin
            @(negedge rd_clk); rd_en = 1;
            @(posedge rd_clk); #1;
            if (dout !== expected) begin $display("FAIL: expected %h got %h", expected, dout); errors = errors + 1; end
            @(negedge rd_clk); rd_en = 0;
        end
    endtask
endmodule
