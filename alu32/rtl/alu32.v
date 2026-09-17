`timescale 1ns/1ps

// 32-bit combinational arithmetic and logic unit.
module alu32 (
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire [4:0]  shamt,
    input  wire [2:0]  opcode,
    output reg  [31:0] result,
    output reg         carry,
    output wire        zero
);

    localparam OP_ADD = 3'b000;
    localparam OP_SUB = 3'b001;
    localparam OP_AND = 3'b010;
    localparam OP_OR  = 3'b011;
    localparam OP_SLL = 3'b100;
    localparam OP_SRL = 3'b101;

    reg [32:0] arithmetic;

    always @* begin
        // Defaults also define the behavior of reserved opcodes.
        result     = 32'b0;
        carry      = 1'b0;
        arithmetic = 33'b0;

        // The default branch makes every opcode value intentional.
        case (opcode)
            OP_ADD: begin
                arithmetic = {1'b0, a} + {1'b0, b};
                result     = arithmetic[31:0];
                carry      = arithmetic[32];
            end
            OP_SUB: begin
                result = a - b;
                // For subtraction, carry indicates no borrow.
                carry  = (a >= b);
            end
            OP_AND: begin
                result = a & b;
            end
            OP_OR: begin
                result = a | b;
            end
            OP_SLL: begin
                result = a << shamt;
            end
            OP_SRL: begin
                result = a >> shamt;
            end
            default: begin
                result = 32'b0;
                carry  = 1'b0;
            end
        endcase
    end

    assign zero = (result == 32'b0);

endmodule
