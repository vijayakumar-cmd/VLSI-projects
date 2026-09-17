`timescale 1ns/1ps

module traffic_light_controller_tb;

    reg clk;
    reg rst;
    wire ns_red, ns_yellow, ns_green;
    wire ew_red, ew_yellow, ew_green;

    integer checks;
    integer failures;

    // Small values keep the testbench fast while exercising real transitions.
    traffic_light_controller #(
        .CLK_FREQ_HZ(4),
        .GREEN_TIME_S(2),
        .YELLOW_TIME_S(1)
    ) dut (
        .clk(clk), .rst(rst),
        .ns_red(ns_red), .ns_yellow(ns_yellow), .ns_green(ns_green),
        .ew_red(ew_red), .ew_yellow(ew_yellow), .ew_green(ew_green)
    );

    always #5 clk = ~clk;

    task expect_lights;
        input exp_ns_red, exp_ns_yellow, exp_ns_green;
        input exp_ew_red, exp_ew_yellow, exp_ew_green;
        begin
            #1;
            checks = checks + 1;
            if ({ns_red, ns_yellow, ns_green, ew_red, ew_yellow, ew_green} !==
                {exp_ns_red, exp_ns_yellow, exp_ns_green, exp_ew_red, exp_ew_yellow, exp_ew_green}) begin
                failures = failures + 1;
                $display("FAIL check %0d: lights=%b%b%b_%b%b%b expected=%b%b%b_%b%b%b",
                    checks, ns_red, ns_yellow, ns_green, ew_red, ew_yellow, ew_green,
                    exp_ns_red, exp_ns_yellow, exp_ns_green,
                    exp_ew_red, exp_ew_yellow, exp_ew_green);
            end
            if ((ns_green && ew_green) || (ns_yellow && ew_green) || (ew_yellow && ns_green)) begin
                failures = failures + 1;
                $display("FAIL safety check %0d: conflicting active lights", checks);
            end
        end
    endtask

    task clock_cycles;
        input integer count;
        integer i;
        begin
            for (i = 0; i < count; i = i + 1) begin
                @(posedge clk);
                expect_lights(1'b0, 1'b0, 1'b1, 1'b1, 1'b0, 1'b0);
            end
        end
    endtask

    initial begin
        clk = 1'b0;
        rst = 1'b1;
        checks = 0;
        failures = 0;

        // Reset starts safely with North/South green and East/West red.
        @(posedge clk);
        #1;
        expect_lights(1'b0, 1'b0, 1'b1, 1'b1, 1'b0, 1'b0);
        rst = 1'b0;

        // Four clock cycles represent two seconds at the test frequency.
        repeat (3) @(posedge clk);
        expect_lights(1'b0, 1'b1, 1'b0, 1'b1, 1'b0, 1'b0);

        // Two cycles represent the one-second yellow interval.
        repeat (2) @(posedge clk);
        expect_lights(1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1);

        repeat (4) @(posedge clk);
        expect_lights(1'b1, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0);

        repeat (2) @(posedge clk);
        expect_lights(1'b0, 1'b0, 1'b1, 1'b1, 1'b0, 1'b0);

        if (failures == 0)
            $display("PASS: %0d traffic-light checks completed", checks);
        else
            $display("FAIL: %0d checks failed", failures);
        $finish;
    end

endmodule
