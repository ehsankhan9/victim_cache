# Define variables
TOP_MODULE = wb_dcache_top_tb
SRC_FILES =  defines/*.svh rtl/*.sv testbench/wb_dcache_top_tb.sv
DEFINES_VER:= defines/*.svh
WORK_DIR = work

# Default target
all: compile run

# Compile source files
compile:
	python3 src/code_ok.py
	@mkdir -p log
	vlib $(WORK_DIR)
	vlog -work $(WORK_DIR) $(SRC_FILES)

# Run the simulation 
view_simulation: compile
	vsim -L $(WORK_DIR) $(TOP_MODULE) -do "add wave -radix Decimal sim:/$(TOP_MODULE)/*; run -all"

# Show the simulation output
simulate: compile
	vsim -c -do "run -all; quit;" -L $(WORK_DIR) $(TOP_MODULE)

# Clean up generated files
clean:
	rm -rf log
	rm -rf $(WORK_DIR) transcript vsim.wlf
	rm -rf *.jou *.log *.pb *.wdb xsim.dir *.str
	rm -rf .*.timestamp *.tcl *.vcd .*.verilate
	rm -rf obj_dir .Xil

.PHONY: all compile simulate clean
