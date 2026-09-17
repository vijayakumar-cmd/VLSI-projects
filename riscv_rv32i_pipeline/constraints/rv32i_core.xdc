# Generic 100 MHz integration clock; assign I/O pins in the SoC-level XDC.
create_clock -name clk -period 10.000 [get_ports clk]
set_input_delay -clock clk 0 [get_ports rst]
