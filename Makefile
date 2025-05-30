# Makefile for FIR Retiming Project
# Supporting multiple simulators and synthesis tools

# Tool Settings
IVERILOG = iverilog
VVP = vvp
GTKWAVE = gtkwave

# Verilog Source Files
SRC_DIR = src
VERILOG_SRCS = $(SRC_DIR)/fir_original.v \
               $(SRC_DIR)/fir_retimed.v \
               $(SRC_DIR)/fir_retiming_tb.v

# Output Files
SIM_OUT = fir_retiming_sim
VCD_FILE = fir_retiming.vcd # Icarus Verilog default output is dump.vcd, tb needs to specify $dumpfile

# Default Target
.PHONY: all
all: sim

# Compile and Simulate (using Icarus Verilog)
.PHONY: sim
sim: $(VERILOG_SRCS)
	@echo "=== Compiling Verilog Files (Icarus Verilog) ==="
	$(IVERILOG) -o $(SIM_OUT) $(VERILOG_SRCS)
	@echo "=== Running Simulation (Icarus Verilog) ==="
	$(VVP) $(SIM_OUT)

# View Waveform (GTKWave)
.PHONY: wave
wave: sim
	@echo "=== Opening Waveform Viewer (GTKWave) ==="
	@echo "Note: Ensure your testbench generates $(VCD_FILE)"
	$(GTKWAVE) $(VCD_FILE) &

# ModelSim Simulation
.PHONY: modelsim
modelsim:
	@echo "=== Running ModelSim Simulation ==="
	cd simulation && vsim -do modelsim.do

# Quartus Project Setup
.PHONY: quartus
quartus:
	@echo "=== Setting up Quartus Project ==="
	cd scripts && quartus_sh -t quartus_project_setup.tcl

# Clean up
.PHONY: clean
clean:
	@echo "=== Cleaning Output Files ==="
	rm -f $(SIM_OUT) $(VCD_FILE) dump.vcd # also remove default dump.vcd
	rm -f *.log *.pb
	rm -rf work/ # For ModelSim
	# Add other tool-specific cleanups if needed

# Help
.PHONY: help
help:
	@echo "FIR Retiming Project Makefile Usage:"
	@echo "  make sim      - Compile and run simulation (using Icarus Verilog)"
	@echo "  make wave     - Run simulation and open waveform viewer (GTKWave)"
	@echo "  make modelsim - Run simulation using ModelSim"
	@echo "  make quartus  - Setup Quartus project"
	@echo "  make clean    - Clean all output files"
	@echo "  make help     - Display this help message" 