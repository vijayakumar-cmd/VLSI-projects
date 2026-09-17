# Reset strategy

The UART transmitter and receiver use a **synchronous active-high reset**:

```verilog
always @(posedge clk) begin
    if (rst) begin
        // reset state and outputs
    end else begin
        // normal operation
    end
end
```

## Required behavior

1. Hold `rst` high for at least one rising edge of `clk` after power-up.
2. Keep the serial line idle high during reset and after reset.
3. Do not assert `start` until reset has been released.
4. A reset during a frame aborts the partial transfer and returns the logic to idle.

On reset, the transmitter clears its byte and counters, deasserts `busy` and `done`, and drives `tx=1`. The receiver clears its state, byte, `valid`, and `framing_error` outputs and waits for a new falling edge on `rx`.

## Integration note

The external UART input is asynchronous to the system clock in a real design. Add a two-flop synchronizer at the top level before connecting it to `uart_rx`, or include the synchronizer in a board-specific wrapper. The core receiver intentionally assumes that `rx` is already synchronized so the RTL remains reusable and easy to verify.
