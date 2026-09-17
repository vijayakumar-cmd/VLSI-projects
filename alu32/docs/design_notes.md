# Design notes

## Datapath

The ALU is purely combinational. The arithmetic path uses a 33-bit temporary so addition overflow is exposed through `carry`; the result remains the low 32 bits. Subtraction is performed with normal two's-complement Verilog arithmetic, and `carry` is defined as `a >= b` to represent no borrow.

The logical and shift operations do not generate a carry. The shift amount is five bits, which is sufficient to select every shift from 0 through 31 for a 32-bit operand. Right shifts are logical because `a` is declared unsigned (`wire [31:0]`).

## Case completeness

The `case` statement includes all six supported operations and a `default` branch for the two reserved opcode values. Outputs are assigned safe defaults before the case statement, preventing inferred latches and ensuring deterministic behavior for invalid inputs.

## Verification plan

`tb/alu32_tb.v` checks:

- Normal addition and unsigned addition overflow.
- Subtraction with and without borrow.
- Representative AND and OR bit masks.
- Left and right shifts.
- Both reserved opcodes and the zero flag.

The testbench uses exact (`!==`) comparisons and reports a nonzero failure count in the transcript. Add randomized checks or assertions when extending the design.
