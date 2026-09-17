`timescale 1ns/1ps

module async_fifo #(
    parameter integer DATA_WIDTH = 8,
    parameter integer ADDR_WIDTH = 4
) (
    input  wire                  wr_clk,
    input  wire                  wr_rst_n,
    input  wire                  wr_en,
    input  wire [DATA_WIDTH-1:0] din,
    output wire                  full,
    output wire [ADDR_WIDTH:0]   wr_level,

    input  wire                  rd_clk,
    input  wire                  rd_rst_n,
    input  wire                  rd_en,
    output reg  [DATA_WIDTH-1:0] dout,
    output wire                  empty,
    output wire [ADDR_WIDTH:0]   rd_level
);
    localparam integer DEPTH = (1 << ADDR_WIDTH);

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [ADDR_WIDTH:0] wr_ptr_bin, wr_ptr_gray;
    reg [ADDR_WIDTH:0] rd_ptr_bin, rd_ptr_gray;
    (* ASYNC_REG = "TRUE" *) reg [ADDR_WIDTH:0] rd_gray_wr_meta, rd_gray_wr_sync;
    (* ASYNC_REG = "TRUE" *) reg [ADDR_WIDTH:0] wr_gray_rd_meta, wr_gray_rd_sync;
    reg full_reg, empty_reg;
    wire do_write = wr_en && !full_reg;
    wire do_read  = rd_en && !empty_reg;
    wire [ADDR_WIDTH:0] wr_ptr_bin_next = wr_ptr_bin + do_write;
    wire [ADDR_WIDTH:0] rd_ptr_bin_next = rd_ptr_bin + do_read;
    wire [ADDR_WIDTH:0] wr_ptr_gray_next = (wr_ptr_bin_next >> 1) ^ wr_ptr_bin_next;
    wire [ADDR_WIDTH:0] rd_ptr_gray_next = (rd_ptr_bin_next >> 1) ^ rd_ptr_bin_next;
    wire [ADDR_WIDTH:0] full_compare = {~rd_gray_wr_sync[ADDR_WIDTH:ADDR_WIDTH-1],
                                         rd_gray_wr_sync[ADDR_WIDTH-2:0]};

    assign full  = full_reg;
    assign empty = empty_reg;
    assign wr_level = wr_ptr_bin - {1'b0, rd_gray_wr_sync};
    assign rd_level = wr_ptr_rd_binary() - rd_ptr_bin;

    // Gray-to-binary conversion is used only for a local-domain occupancy estimate.
    function [ADDR_WIDTH:0] wr_ptr_rd_binary;
        integer i;
        begin
            wr_ptr_rd_binary[ADDR_WIDTH] = wr_gray_rd_sync[ADDR_WIDTH];
            for (i = ADDR_WIDTH-1; i >= 0; i = i-1)
                wr_ptr_rd_binary[i] = wr_ptr_rd_binary[i+1] ^ wr_gray_rd_sync[i];
        end
    endfunction

    always @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            rd_gray_wr_meta <= {ADDR_WIDTH+1{1'b0}};
            rd_gray_wr_sync <= {ADDR_WIDTH+1{1'b0}};
        end else begin
            rd_gray_wr_meta <= rd_ptr_gray;
            rd_gray_wr_sync <= rd_gray_wr_meta;
        end
    end

    always @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            wr_gray_rd_meta <= {ADDR_WIDTH+1{1'b0}};
            wr_gray_rd_sync <= {ADDR_WIDTH+1{1'b0}};
        end else begin
            wr_gray_rd_meta <= wr_ptr_gray;
            wr_gray_rd_sync <= wr_gray_rd_meta;
        end
    end

    always @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            wr_ptr_bin  <= {ADDR_WIDTH+1{1'b0}};
            wr_ptr_gray <= {ADDR_WIDTH+1{1'b0}};
            full_reg    <= 1'b0;
        end else begin
            if (do_write)
                mem[wr_ptr_bin[ADDR_WIDTH-1:0]] <= din;
            wr_ptr_bin  <= wr_ptr_bin_next;
            wr_ptr_gray <= wr_ptr_gray_next;
            full_reg    <= (wr_ptr_gray_next == full_compare);
        end
    end

    always @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            rd_ptr_bin  <= {ADDR_WIDTH+1{1'b0}};
            rd_ptr_gray <= {ADDR_WIDTH+1{1'b0}};
            empty_reg   <= 1'b1;
            dout        <= {DATA_WIDTH{1'b0}};
        end else begin
            if (do_read)
                dout <= mem[rd_ptr_bin[ADDR_WIDTH-1:0]];
            rd_ptr_bin  <= rd_ptr_bin_next;
            rd_ptr_gray <= rd_ptr_gray_next;
            empty_reg   <= (rd_ptr_gray_next == wr_gray_rd_sync);
        end
    end
endmodule
