# Simulation commands

From `fifo/`:

```bash
mkdir -p build
iverilog -g2012 -o build/sync_fifo_tb rtl/sync_fifo.v tb/sync_fifo_tb.v
vvp build/sync_fifo_tb

iverilog -g2012 -o build/async_fifo_tb rtl/async_fifo.v tb/async_fifo_tb.v
vvp build/async_fifo_tb
```

For Vivado, add RTL files as design sources and testbenches as simulation sources. Select either testbench as the simulation top.
