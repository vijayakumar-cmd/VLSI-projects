`timescale 1ns/1ps

// Two-road traffic light controller for a 100 MHz Basys-3 clock.
module traffic_light_controller #(
    parameter integer CLK_FREQ_HZ   = 100_000_000,
    parameter integer GREEN_TIME_S  = 10,
    parameter integer YELLOW_TIME_S = 3
) (
    input  wire clk,
    input  wire rst,
    output reg  ns_red,
    output reg  ns_yellow,
    output reg  ns_green,
    output reg  ew_red,
    output reg  ew_yellow,
    output reg  ew_green
);

    localparam [1:0] ST_NS_GREEN  = 2'b00;
    localparam [1:0] ST_NS_YELLOW = 2'b01;
    localparam [1:0] ST_EW_GREEN  = 2'b10;
    localparam [1:0] ST_EW_YELLOW = 2'b11;

    localparam integer GREEN_CYCLES  = CLK_FREQ_HZ * GREEN_TIME_S;
    localparam integer YELLOW_CYCLES = CLK_FREQ_HZ * YELLOW_TIME_S;

    reg [1:0] state;
    reg [1:0] next_state;
    integer elapsed_cycles;
    integer state_limit;

    // Moore next-state logic. Every legal state has an explicit transition.
    always @* begin
        next_state = state;
        case (state)
            ST_NS_GREEN:  if (elapsed_cycles >= state_limit - 1) next_state = ST_NS_YELLOW;
            ST_NS_YELLOW: if (elapsed_cycles >= state_limit - 1) next_state = ST_EW_GREEN;
            ST_EW_GREEN:  if (elapsed_cycles >= state_limit - 1) next_state = ST_EW_YELLOW;
            ST_EW_YELLOW: if (elapsed_cycles >= state_limit - 1) next_state = ST_NS_GREEN;
            default:      next_state = ST_NS_GREEN;
        endcase
    end

    // Select the duration associated with the current state.
    always @* begin
        case (state)
            ST_NS_GREEN, ST_EW_GREEN: state_limit = GREEN_CYCLES;
            ST_NS_YELLOW, ST_EW_YELLOW: state_limit = YELLOW_CYCLES;
            default: state_limit = GREEN_CYCLES;
        endcase
    end

    always @(posedge clk) begin
        if (rst) begin
            state          <= ST_NS_GREEN;
            elapsed_cycles <= 0;
        end else if (next_state != state) begin
            state          <= next_state;
            elapsed_cycles <= 0;
        end else if (elapsed_cycles < state_limit) begin
            elapsed_cycles <= elapsed_cycles + 1;
        end
    end

    // Safe default is all red. Each state then enables exactly one green or yellow lamp.
    always @* begin
        ns_red    = 1'b1;
        ns_yellow = 1'b0;
        ns_green  = 1'b0;
        ew_red    = 1'b1;
        ew_yellow = 1'b0;
        ew_green  = 1'b0;

        case (state)
            ST_NS_GREEN: begin
                ns_red   = 1'b0;
                ns_green = 1'b1;
            end
            ST_NS_YELLOW: begin
                ns_red    = 1'b0;
                ns_yellow = 1'b1;
            end
            ST_EW_GREEN: begin
                ew_red   = 1'b0;
                ew_green = 1'b1;
            end
            ST_EW_YELLOW: begin
                ew_red    = 1'b0;
                ew_yellow = 1'b1;
            end
            default: begin
                // Both directions remain red for an illegal state.
            end
        endcase
    end

endmodule
