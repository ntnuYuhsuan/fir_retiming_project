# Quartus Prime Project Setup Script: quartus_project_setup.tcl

# --------------------------------------------------------------------------
# Project Settings
# --------------------------------------------------------------------------
# Project name (can be changed)
set project_name "fir_retiming_fpga"

# Top-level entity name (must match your Verilog top-level module)
# This script can be adapted or run искусство for each top-level (original vs. retimed)
# Defaulting to fir_original. Change as needed.
set top_level_entity "fir_original"
# To set for retimed version, uncomment the line below and comment the one above
# set top_level_entity "fir_retimed"

# FPGA device (MUST BE MODIFIED to your actual device)
# Example for a Cyclone V device
set fpga_family "Cyclone V"
set fpga_device "5CSEMA5F31C6" # Replace with your specific device part number

# Verilog/SystemVerilog source files
# Paths are relative to the project root directory where the .qpf will be created
# This script is intended to be run from the 'scripts' directory, so paths use ../
set verilog_files [list \
    "../src/fir_original.v" \
    "../src/fir_retimed.v" \
    # Add other shared Verilog files here if any
]

# SDC timing constraints file
set sdc_file "../constraints/timing_constraints.sdc"

# --------------------------------------------------------------------------
# Quartus Tcl Commands
# --------------------------------------------------------------------------

# Create a new project (or open if it exists, though -overwrite is often used for scripting)
# Ensure the project is created in the root directory, not inside 'scripts'
project_new ../$project_name -overwrite

# Set top-level entity
set_global_assignment -name TOP_LEVEL_ENTITY $top_level_entity

# Set FPGA family and device
set_global_assignment -name FAMILY "$fpga_family"
set_global_assignment -name DEVICE $fpga_device

# Add Verilog/SystemVerilog source files
# Quartus usually auto-detects SystemVerilog features in .v files
# If specific language version is needed, it can be set.
foreach v_file $verilog_files {
    set_global_assignment -name VERILOG_FILE $v_file
    # For explicit SystemVerilog:
    # set_global_assignment -name SYSTEMVERILOG_FILE $v_file
}

# Add SDC timing constraints file
if {[file exists $sdc_file]} {
    set_global_assignment -name SDC_FILE $sdc_file
} else {
    post_message -type warning "SDC file not found at expected path: $sdc_file (relative to script location)"
}

# Optional: Set other project assignments
# e.g., set_global_assignment -name EDA_SIMULATION_TOOL "ModelSim (Verilog)"
# e.g., set_global_assignment -name EDA_TEST_BENCH_ENABLE_STATUS TEST_BENCH_MODE_CLASSIC -section_id eda_simulation
# e.g., set_global_assignment -name EDA_TEST_BENCH_NAME fir_retiming_tb -section_id eda_simulation
# e.g., set_global_assignment -name EDA_TEST_BENCH_FILE ../src/fir_retiming_tb.v -section_id eda_simulation

# Save and close the project
project_close

post_message "Quartus project '../$project_name.qpf' setup complete for top-level entity '$top_level_entity'."
post_message "Please ensure the FPGA device ($fpga_device) is correct for your board."
post_message "To run this script, open Quartus, go to Tools > Tcl Scripts, and select this file, or run from Quartus shell: quartus_sh -t quartus_project_setup.tcl" 