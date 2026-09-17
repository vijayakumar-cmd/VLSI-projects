# Traffic Light Controller FSM

A synthesizable Verilog traffic light controller for the Digilent Basys-3 FPGA. The design uses a four-state finite state machine and a clock-divider timing counter to control a two-road intersection:

- North/South green, then yellow.
- East/West green, then yellow.
- Safe one-hot-style light outputs with no simultaneous green lights.

## Directory layout

```text
traffic_light_controller/
├── README.md
├── rtl/
│   └── traffic_light_controller.v
├── tb/
│   └── traffic_light_controller_tb.v
├── sim/
│   └── run.do
├── constraints/
│   └── basys3_traffic_light.xdc
└── docs/
    └── design_notes.md
```

## Timing

The RTL is parameterized for simulation and synthesis:

- `CLK_FREQ_HZ`: input clock frequency; default is 100 MHz for Basys-3.
- `GREEN_TIME_S`: green-light duration; default is 10 seconds.
- `YELLOW_TIME_S`: yellow-light duration; default is 3 seconds.

The counter advances once per input-clock cycle. A state changes after its configured number of seconds. For quick simulation, override the parameters with small values, as done by the testbench.

## Interface

- `clk`: 100 MHz Basys-3 oscillator input.
- `rst`: synchronous active-high reset, connected to the center pushbutton.
- `ns_red`, `ns_yellow`, `ns_green`: North/South lamps.
- `ew_red`, `ew_yellow`, `ew_green`: East/West lamps.

The output decoder is Moore-style: outputs depend only on the registered FSM state. During reset, both directions are red.

## Basys-3 setup

1. Add `rtl/traffic_light_controller.v` as the top-level source in Vivado.
2. Add `constraints/basys3_traffic_light.xdc`.
3. Select the Basys-3 board or the `xc7a35tcpg236-1` part.
4. Generate the bitstream and program the board.
5. Press the center button to reset the controller.

The XDC maps the six lamps to `LED0` through `LED5`: three LEDs for North/South and three for East/West.

## ModelSim / QuestaSim

From this directory:

```text
vsim -do sim/run.do
```

The testbench uses a small clock and short timing parameters, checks every FSM transition, verifies reset behavior, and asserts that both roads never receive green simultaneously.
