# Simulation instructions

## Icarus Verilog

From `uart_protocol/`:

```bash
mkdir -p build
iverilog -g2012 -o build/uart_tb rtl/uart_tx.v rtl/uart_rx.v tb/uart_tb.v
vvp build/uart_tb
```

The testbench uses `CLKS_PER_BIT=8` so the simulation completes quickly. It loops the transmitter output into the receiver and checks that `8'hA5` is received without a framing error.

## ModelSim / Questa command line

From `uart_protocol/`:

```tcl
vlib work
vlog rtl/uart_tx.v rtl/uart_rx.v tb/uart_tb.v
vsim -c uart_tb -do "run -all; quit -f"
```

For waveform inspection:

```tcl
vsim work.uart_tb
add wave -r /*
run -all
```

The RTL files contain no simulator-specific delays; the only delay in the testbench is the clock generation and final simulation control.
