`timescale 1ns/1ps

module alu32_tb;

    reg  [31:0] a;
    reg  [31:0] b;
    reg  [4:0]  shamt;
    reg  [2:0]  opcode;
    wire [31:0] result;
    wire        carry;
    wire        zero;

    integer checks;
    integer failures;

    localparam OP_ADD = 3'b000;
    localparam OP_SUB = 3'b001;
    localparam OP_AND = 3'b010;
    localparam OP_OR  = 3'b011;
    localparam OP_SLL = 3'b100;
    localparam OP_SRL = 3'b101;

    alu32 dut (
        .a(a),
        .b(b),
        .shamt(shamt),
        .opcode(opcode),
        .result(result),
        .carry(carry),
        .zero(zero)
    );

    task check;
        input [2:0]  test_opcode;
        input [31:0] test_a;
        input [31:0] test_b;
        input [4:0]  test_shamt;
        input [31:0] expected_result;
        input        expected_carry;
        input        expected_zero;
        begin
            a      = test_a;
            b      = test_b;
            shamt  = test_shamt;
            opcode = test_opcode;
            #1;
            checks = checks + 1;
            if ((result !== expected_result) ||
                (carry  !== expected_carry)  ||
                (zero   !== expected_zero)) begin
                failures = failures + 1;
                $display("FAIL check %0d: op=%b a=%h b=%h shamt=%0d result=%h/%h carry=%b/%b zero=%b/%b",
                         checks, opcode, a, b, shamt, result, expected_result,
                         carry, expected_carry, zero, expected_zero);
            end
        end
    endtask

    initial begin
        checks  = 0;
        failures = 0;
        a       = 32'b0;
        b       = 32'b0;
        shamt   = 5'b0;
        opcode  = OP_ADD;

        check(OP_ADD, 32'd10, 32'd20, 5'd0, 32'd30, 1'b0, 1'b0);
        check(OP_ADD, 32'hffff_ffff, 32'd1, 5'd0, 32'h0000_0000, 1'b1, 1'b1);
        check(OP_SUB, 32'd20, 32'd7, 5'd0, 32'd13, 1'b1, 1'b0);
        check(OP_SUB, 32'd7, 32'd20, 5'd0, 32'hffff_fff3, 1'b0, 1'b0);
        check(OP_AND, 32'hffff_00f0, 32'h0f0f_ffff, 5'd0, 32'h0f0f_00f0, 1'b0, 1'b0);
        check(OP_OR,  32'h0000_00f0, 32'h0000_0f00, 5'd0, 32'h0000_0ff0, 1'b0, 1'b0);
        check(OP_SLL, 32'h0000_0001, 32'b0, 5'd8, 32'h0000_0100, 1'b0, 1'b0);
        check(OP_SRL, 32'h8000_0000, 32'b0, 5'd4, 32'h0800_0000, 1'b0, 1'b0);
        check(3'b110, 32'h1234_5678, 32'hffff_ffff, 5'd3, 32'b0, 1'b0, 1'b1);
        check(3'b111, 32'h1234_5678, 32'hffff_ffff, 5'd3, 32'b0, 1'b0, 1'b1);

        if (failures == 0)
            $display("PASS: %0d ALU checks completed", checks);
        else
            $display("FAIL: %0d of %0d ALU checks failed", failures, checks);

        $finish;
    end

endmodule
