# UART Protocol (Transmitter + Receiver)

A small, synthesizable 8-bit UART implementation in Verilog with matching transmitter and receiver modules. The design targets a standard **8 data bits, no parity, 1 stop bit (8N1)** frame and can be simulated with either Icarus Verilog or ModelSim/Questa.

## Features

- Parameterized `CLKS_PER_BIT` baud-rate divider.
- Independent UART transmitter and receiver.
- Synthesizable RTL; no delays or simulator-only constructs in the design files.
- Synchronous, active-high reset strategy.
- Receiver start-bit validation and framing-error reporting.
- Self-checking loopback testbench.

## Directory layout

```text
uart_protocol/
├── README.md
├── rtl/
│   ├── uart_tx.v
│   └── uart_rx.v
├── tb/
│   └── uart_tb.v
├── sim/
│   └── README.md
└── docs/
    └── reset_strategy.md
```

## UART timing

For a system clock frequency `F_CLK` and desired baud rate `BAUD`:

```text
CLKS_PER_BIT = F_CLK / BAUD
```

The default RTL parameter is `CLKS_PER_BIT = 434`, which is approximately 115200 baud for a 50 MHz clock. Use an integer divider selected for the target clock and baud rate.

Each frame is transmitted least-significant bit first:

```text
idle (1) -> start (0) -> data[0] ... data[7] -> stop (1)
```

## Interfaces

### `uart_tx`

- `clk`, `rst`: clock and synchronous active-high reset.
- `start`: one-cycle request to transmit `data_in`; ignored while `busy` is high.
- `data_in[7:0]`: byte to transmit.
- `tx`: serial output, idle high.
- `busy`: asserted during the complete frame.
- `done`: one-cycle pulse after the stop bit.

### `uart_rx`

- `clk`, `rst`: clock and synchronous active-high reset.
- `rx`: serial input, expected idle high.
- `data_out[7:0]`: most recently received byte.
- `valid`: one-cycle pulse when a correctly framed byte is available.
- `framing_error`: one-cycle pulse when the stop bit is not high.

The receiver waits half a bit after detecting the falling edge of the start bit, validates the start bit, and then samples each data bit at its bit center.

## Run with Icarus Verilog

From this directory:

```bash
mkdir -p build
iverilog -g2012 -o build/uart_tb \
  rtl/uart_tx.v rtl/uart_rx.v tb/uart_tb.v
vvp build/uart_tb
```

Expected output includes:

```text
PASS: received 0xA5
PASS: UART loopback test completed
```

## Run with ModelSim / Questa

See [`sim/README.md`](sim/README.md) for command-line and GUI-oriented instructions.

## Reset strategy

Both modules use a synchronous active-high reset. Assert `rst` high for at least one rising edge of `clk` before normal operation. Reset returns the transmitter output and receiver input state to UART idle, clears status pulses, and removes any partial frame. See [`docs/reset_strategy.md`](docs/reset_strategy.md).

## Synthesis notes

- `CLKS_PER_BIT` must be a positive integer.
- The divider is integer-based; for fractional baud-rate accuracy, replace the counter with a clock-enable accumulator.
- The asynchronous external `rx` input should be synchronized to `clk` in the FPGA/top-level integration. The included receiver assumes its `rx` input is already in the `clk` domain.
