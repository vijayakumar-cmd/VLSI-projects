transcript on
if {[file exists work]} {
    vdel -lib work -all
}
vlib work
vmap work work
vlog rtl/traffic_light_controller.v tb/traffic_light_controller_tb.v
vsim -c traffic_light_controller_tb
run -all
quit -f
