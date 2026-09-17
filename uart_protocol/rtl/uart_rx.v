`timescale 1ns/1ps

// Synthesizable UART receiver, 8 data bits, no parity, 1 stop bit.
module uart_rx #(
    parameter integer CLKS_PER_BIT = 434
) (
    input  wire       clk,
    input  wire       rst,
    input  wire       rx,
    output reg [7:0] data_out,
    output reg        valid,
    output reg        framing_error
);
    localparam integer HALF_CLKS = (CLKS_PER_BIT < 2) ? 1 : CLKS_PER_BIT / 2;
    localparam integer COUNT_WIDTH = (CLKS_PER_BIT <= 1) ? 1 : $clog2(CLKS_PER_BIT);
    localparam [2:0] ST_IDLE        = 3'd0;
    localparam [2:0] ST_START_CHECK = 3'd1;
    localparam [2:0] ST_DATA        = 3'd2;
    localparam [2:0] ST_STOP        = 3'd3;

    reg [2:0] state;
    reg [COUNT_WIDTH-1:0] clock_count;
    reg [2:0] bit_index;
    reg [7:0] data_reg;

    always @(posedge clk) begin
        if (rst) begin
            state         <= ST_IDLE;
            clock_count   <= {COUNT_WIDTH{1'b0}};
            bit_index     <= 3'd0;
            data_reg      <= 8'd0;
            data_out      <= 8'd0;
            valid         <= 1'b0;
            framing_error <= 1'b0;
        end else begin
            valid         <= 1'b0;
            framing_error <= 1'b0;

            case (state)
                ST_IDLE: begin
                    clock_count <= {COUNT_WIDTH{1'b0}};
                    bit_index   <= 3'd0;
                    if (!rx) begin
                        state       <= ST_START_CHECK;
                        clock_count <= {COUNT_WIDTH{1'b0}};
                    end
                end

                ST_START_CHECK: begin
                    if (clock_count == HALF_CLKS-1) begin
                        clock_count <= {COUNT_WIDTH{1'b0}};
                        if (!rx) begin
                            state     <= ST_DATA;
                            bit_index <= 3'd0;
                        end else begin
                            state <= ST_IDLE;
                        end
                    end else begin
                        clock_count <= clock_count + 1'b1;
                    end
                end

                ST_DATA: begin
                    if (clock_count == CLKS_PER_BIT-1) begin
                        clock_count         <= {COUNT_WIDTH{1'b0}};
                        data_reg[bit_index] <= rx;
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
                    if (clock_count == CLKS_PER_BIT-1) begin
                        clock_count <= {COUNT_WIDTH{1'b0}};
                        state       <= ST_IDLE;
                        if (rx) begin
                            data_out <= data_reg;
                            valid    <= 1'b1;
                        end else begin
                            framing_error <= 1'b1;
                        end
                    end else begin
                        clock_count <= clock_count + 1'b1;
                    end
                end

                default: state <= ST_IDLE;
            endcase
        end
    end
endmodule
