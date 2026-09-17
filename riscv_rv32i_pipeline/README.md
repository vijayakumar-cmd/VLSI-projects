# RV32I Five-Stage Pipeline Core

Educational SystemVerilog RV32I processor demonstrating a classic IF/ID/EX/MEM/WB pipeline, register forwarding, load-use hazard detection, and static-not-taken branch prediction. The core is suitable for simulation in ModelSim/Questa and synthesis experiments with Vivado or OpenLane.

## Implemented instructions

- Register/immediate ALU: `ADD`, `SUB`, `AND`, `OR`, `XOR`, `SLL`, `SRL`, `SRA`, `SLT`, `SLTU`
- Immediate: `ADDI`, `ANDI`, `ORI`, `XORI`, `SLLI`, `SRLI`, `SRAI`, `SLTI`, `SLTIU`
- Loads/stores: `LW`, `SW`
- Control flow: `BEQ`, `BNE`, `BLT`, `BGE`, `BLTU`, `BGEU`, `JAL`, `JALR`
- `LUI`, `AUIPC`
- `FENCE` and unsupported encodings are treated as no-ops

The implementation is RV32I only: there are no CSRs, interrupts, caches, MMU, or compressed instructions.

## Pipeline and hazards

1. **IF** fetches the instruction at `pc` and predicts every conditional branch not taken.
2. **ID** decodes the instruction and reads the register file.
3. **EX** performs the ALU operation and resolves branches.
4. **MEM** accesses the external data-memory interface.
5. **WB** writes results back to `x1`–`x31`.

A load-use dependency inserts one bubble and holds PC/IF-ID. ALU results are forwarded from EX/MEM and MEM/WB into EX. Taken branches and jumps flush younger instructions and redirect the PC. Branch prediction is deliberately static not-taken; this keeps the predictor simple while making the misprediction penalty visible.

## Directory layout

```text
riscv_rv32i_pipeline/
├── README.md
├── rtl/rv32i_core.sv
├── tb/rv32i_core_tb.sv
├── sim/run.do
├── constraints/rv32i_core.xdc
├── openlane/config.json
└── docs/design_notes.md
```

## Core interface

- `imem_addr`, `imem_rdata`: combinational instruction-fetch address/data interface.
- `dmem_valid`, `dmem_we`, `dmem_addr`, `dmem_wdata`, `dmem_wstrb`: data-memory request interface.
- `dmem_rdata`: read data returned combinationally for a valid load.
- `halted`: asserted after an all-zero instruction reaches the core, useful for simulation.

The memory interfaces are intentionally simple; add a bus adapter or cache for a target SoC.

## Simulation

With ModelSim/Questa:

```text
cd riscv_rv32i_pipeline
vsim -do sim/run.do
```

The self-checking testbench uses tiny combinational memories, exercises forwarding, a load-use stall, a taken branch, a store, and verifies the final register/memory results.

## Synthesis notes

The XDC contains a generic 100 MHz clock constraint for integration into a Vivado project. The OpenLane configuration targets a generic SKY130 flow and uses `rv32i_core` as the top-level module. Memory arrays should normally be replaced with technology-specific macros or external interfaces before timing closure.
