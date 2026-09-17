# Parameterizable Synchronous / Asynchronous FIFO

This project contains synthesizable Verilog FIFO implementations for Xilinx Vivado and simulation with Icarus Verilog:

- `sync_fifo`: single-clock FIFO with parameterized width and depth.
- `async_fifo`: dual-clock FIFO using Gray-coded pointers and two-flop clock-domain synchronizers.
- Self-checking testbenches for both implementations.

## Features

- Parameterized data width.
- Parameterized depth for the synchronous FIFO.
- Power-of-two depth for the asynchronous FIFO, as required by the Gray-pointer full/empty algorithm.
- Registered `full`, `empty`, and count/status outputs.
- Safe handling of attempted writes while full and reads while empty.
- No vendor primitives; suitable for Vivado synthesis and portability.

## Directory layout

```text
fifo/
├── README.md
├── rtl/
│   ├── sync_fifo.v
│   └── async_fifo.v
├── tb/
│   ├── sync_fifo_tb.v
│   └── async_fifo_tb.v
├── sim/
│   └── README.md
└── docs/
    └── design_notes.md
```

## Interfaces

### `sync_fifo`

- `clk`, `rst`: clock and synchronous active-high reset.
- `wr_en`, `din`: write request and input data.
- `rd_en`, `dout`: read request and output data.
- `full`, `empty`: FIFO status flags.
- `count`: number of stored words.

A write is accepted only when `wr_en && !full`; a read is accepted only when `rd_en && !empty`. `dout` is registered and updates on an accepted read.

### `async_fifo`

- `wr_clk`, `wr_rst_n`, `wr_en`, `din`, `full`: write-side interface.
- `rd_clk`, `rd_rst_n`, `rd_en`, `dout`, `empty`: read-side interface.
- `wr_level`, `rd_level`: local-domain approximate occupancy values.

The asynchronous FIFO uses independent clocks and active-low asynchronous resets. Its `ADDR_WIDTH` must be at least 2 and its depth is `2**ADDR_WIDTH`; for example, `ADDR_WIDTH=4` creates a 16-word FIFO. Only synchronized Gray-coded pointers cross clock domains.

## Run with Icarus Verilog

From this directory:

```bash
mkdir -p build
iverilog -g2012 -o build/sync_fifo_tb rtl/sync_fifo.v tb/sync_fifo_tb.v
vvp build/sync_fifo_tb

iverilog -g2012 -o build/async_fifo_tb rtl/async_fifo.v tb/async_fifo_tb.v
vvp build/async_fifo_tb
```

Both simulations print a `PASS` message and finish with `$finish`.

## Vivado

Add the two files in `rtl/` as design sources and choose the required FIFO module as the top-level design. Add the matching testbench in `tb/` as a simulation source. The RTL uses standard Verilog constructs and does not require Xilinx IP.

For the asynchronous FIFO, constrain `wr_clk` and `rd_clk` separately and document the intended clock relationship. The two-flop synchronizers are marked with `(* ASYNC_REG = "TRUE" *)` for implementation tools.

## Reset guidance

For `sync_fifo`, hold `rst` high for at least one rising edge of `clk`. For `async_fifo`, assert both active-low resets together during startup and release them only after both clock domains are running. Resetting only one side while the FIFO contains data is not a supported flush operation.
