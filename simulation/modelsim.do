# ModelSim Simulation Script: modelsim.do

# 0. Cleanup (optional)
# If 'work' library exists, delete it for a clean compile
if {[file exists work]} {
    vdel -all
}
# Create 'work' library
vlib work

# 1. Compile Verilog/SystemVerilog Files
#    - Paths should be relative to where this .do file is, or use absolute/relative to sim execution dir.
#    - Assuming this .do file is in 'simulation' and source is in 'src'.
#    - vlog -sv <filename> for SystemVerilog files.

echo "Compiling source files..."
# Compile design files
vlog -sv -work work ../src/fir_original.v
vlog -sv -work work ../src/fir_retimed.v

# Compile testbench file
vlog -sv -work work ../src/fir_retiming_tb.v

# 2. Simulation Setup & Execution
#    - vsim is the command to start the simulator.
#    - -L <library_name> to link compiled libraries.
#    - +acc to enable access to signals for waveform debugging.
#    - work.<testbench_module_name> to specify the top testbench module.

echo "Starting simulation of fir_retiming_tb..."
# Use -suppress for common informational messages if desired, e.g., 12110 for unused SV features
vsim -L work work.fir_retiming_tb -suppress 12110 

# 3. Waveform Configuration
#    - 'add wave' command adds signals to the wave window.

# Add testbench top-level signals
add wave -divider "Testbench Signals"
add wave sim:/fir_retiming_tb/clk
add wave sim:/fir_retiming_tb/reset_n
add wave sim:/fir_retiming_tb/ena
add wave sim:/fir_retiming_tb/data_in
add wave sim:/fir_retiming_tb/data_out_orig
add wave sim:/fir_retiming_tb/data_out_retimed
add wave sim:/fir_retiming_tb/data_out_orig_delayed_3
add wave sim:/fir_retiming_tb/cycle_count
add wave sim:/fir_retiming_tb/errors

# Add fir_original internal signals (example - can be more specific)
add wave -divider "FIR Original Internals"
add wave -r sim:/fir_retiming_tb/u_fir_original/*

# Add fir_retimed internal signals (example - can be more specific)
add wave -divider "FIR Retimed Internals"
add wave -r sim:/fir_retiming_tb/u_fir_retimed/*

# 4. Run Simulation
#    - 'run -all' runs simulation until $finish is called or stopped manually.

echo "Running simulation..."
run -all

echo "Simulation finished. Check transcript for results and errors." 