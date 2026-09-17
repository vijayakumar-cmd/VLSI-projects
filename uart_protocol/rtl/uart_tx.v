`timescale 1ns/1ps

// Synthesizable UART transmitter, 8 data bits, no parity, 1 stop bit.
module uart_tx #(
    parameter integer CLKS_PER_BIT = 434
) (
    input  wire       clk,
    input  wire       rst,
    input  wire       start,
    input  wire [7:0] data_in,
    output reg        tx,
    output reg        busy,
    output reg        done
);
    localparam integer COUNT_WIDTH = (CLKS_PER_BIT <= 1) ? 1 : $clog2(CLKS_PER_BIT);
    localparam [2:0] ST_IDLE  = 3'd0;
    localparam [2:0] ST_START = 3'd1;
    localparam [2:0] ST_DATA  = 3'd2;
    localparam [2:0] ST_STOP  = 3'd3;

    reg [2:0] state;
    reg [COUNT_WIDTH-1:0] clock_count;
    reg [2:0] bit_index;
    reg [7:0] data_reg;

    always @(posedge clk) begin
        if (rst) begin
            state       <= ST_IDLE;
            clock_count <= {COUNT_WIDTH{1'b0}};
            bit_index   <= 3'd0;
            data_reg    <= 8'd0;
            tx          <= 1'b1;
            busy        <= 1'b0;
            done        <= 1'b0;
        end else begin
            done <= 1'b0;
            case (state)
                ST_IDLE: begin
                    tx          <= 1'b1;
                    busy        <= 1'b0;
                    clock_count <= {COUNT_WIDTH{1'b0}};
                    bit_index   <= 3'd0;
                    if (start) begin
                        data_reg <= data_in;
                        state    <= ST_START;
                        busy     <= 1'b1;
                    end
                end

                ST_START: begin
                    tx <= 1'b0;
                    if (clock_count == CLKS_PER_BIT-1) begin
                        clock_count <= {COUNT_WIDTH{1'b0}};
                        state       <= ST_DATA;
                    end else begin
                        clock_count <= clock_count + 1'b1;
                    end
                end

                ST_DATA: begin
                    tx <= data_reg[bit_index];
                    if (clock_count == CLKS_PER_BIT-1) begin
                        clock_count <= {COUNT_WIDTH{1'b0}};
                        if (bit_index == 3'd7) begin
                            state <= ST_STOP;
                        end else begin
                            bit_index <= bit_index + 1'b1;
                        end
                    end else begin
                        clock_count <= clock_count + 1'b1;
                    end
                end

                ST_STOP: begin
                    tx <= 1'b1;
                    if (clock_count == CLKS_PER_BIT-1) begin
                        clock_count <= {COUNT_WIDTH{1'b0}};
                        state       <= ST_IDLE;
                        busy        <= 1'b0;
                        done        <= 1'b1;
                    end else begin
                        clock_count <= clock_count + 1'b1;
                    end
                end

                default: state <= ST_IDLE;
            endcase
        end
    end
endmodule
