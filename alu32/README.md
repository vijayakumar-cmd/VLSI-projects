# 32-bit ALU

A synthesizable 32-bit arithmetic and logic unit (ALU) written in Verilog. The project demonstrates bit manipulation, a complete opcode `case` statement, and a self-checking ModelSim testbench.

## Operations

| Opcode | Operation | Result |
|:------:|-----------|--------|
| `3'b000` | ADD | `a + b` |
| `3'b001` | SUB | `a - b` |
| `3'b010` | AND | `a & b` |
| `3'b011` | OR | `a | b` |
| `3'b100` | Shift left | `a << shamt` |
| `3'b101` | Shift right | `a >> shamt` |
| `3'b110`–`3'b111` | Reserved | `32'b0` |

The shift operations are logical shifts and use the five-bit `shamt` input. Addition and subtraction produce a `carry` status bit; for subtraction it is the inverse of the borrow (`a >= b`). The `zero` output is asserted when `result` is zero.

## Directory layout

```text
alu32/
├── README.md
├── rtl/
│   └── alu32.v
├── tb/
│   └── alu32_tb.v
├── sim/
│   └── run.do
└── docs/
    └── design_notes.md
```

## Interface

- `a`, `b`: 32-bit operands.
- `shamt`: five-bit logical shift amount from 0 to 31.
- `opcode`: operation selector listed above.
- `result`: 32-bit combinational ALU result.
- `carry`: arithmetic carry/no-borrow status; zero for logical and shift operations.
- `zero`: high when `result` is zero.

## Run with ModelSim / QuestaSim

From the repository root:

```text
cd alu32
vsim -do sim/run.do
```

The script creates the `work` library, compiles the RTL and testbench, runs the self-checking testbench, and exits with `PASS` when all checks succeed. It can also be run from the ModelSim console:

```text
vlib work
vlog rtl/alu32.v tb/alu32_tb.v
vsim -c alu32_tb -do "run -all; quit -f"
```

The RTL is Verilog-2001 compatible and does not use vendor primitives.
