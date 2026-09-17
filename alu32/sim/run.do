transcript on
if {[file exists work]} {
    vdel -lib work -all
}
vlib work
vmap work work
vlog -cover bcestf rtl/alu32.v tb/alu32_tb.v
vsim -c -coverage alu32_tb
run -all
coverage report -detail -codeAll
quit -f
