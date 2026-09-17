# Design notes

## FSM

The controller has four Moore states:

1. `ST_NS_GREEN`
2. `ST_NS_YELLOW`
3. `ST_EW_GREEN`
4. `ST_EW_YELLOW`

The sequence repeats continuously. There is no state in which both roads are green. The default output pattern is all red, so an illegal or unknown state fails safe rather than enabling conflicting traffic.

## Timing implementation

`elapsed_cycles` counts input-clock cycles while the current state is active. The state limit is selected from the configured green or yellow duration. On the terminal count, the registered state changes and the elapsed counter returns to zero.

For the Basys-3 oscillator:

```text
GREEN_CYCLES  = 100,000,000 * GREEN_TIME_S
YELLOW_CYCLES = 100,000,000 * YELLOW_TIME_S
```

The parameters are intentionally configurable. The testbench uses a 4 Hz clock, 2-second green intervals, and 1-second yellow intervals to verify the sequence without waiting for hardware-scale simulation times.

## Hardware considerations

The reset input is synchronous, so hold the center button long enough to include a rising clock edge. The supplied XDC uses the Basys-3 master XDC pin assignments for the 100 MHz clock, center button, and six user LEDs. If a different board revision or LED mapping is used, update the constraints rather than the RTL.
