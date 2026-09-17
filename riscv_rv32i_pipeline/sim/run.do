transcript on
if {[file exists work]} { vdel -lib work -all }
vlib work
vmap work work
vlog -sv rtl/rv32i_core.sv tb/rv32i_core_tb.sv
vsim -c rv32i_core_tb
run -all
quit -f
