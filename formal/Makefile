# Makefile

# defaults
SIM ?= ghdl
# SIM ?= modelsim
TOPLEVEL_LANG ?= vhdl

EXTRA_ARGS += --std=08
SIM_ARGS += --wave=wave.ghw

VHDL_SOURCES += $(PWD)/../rtl/barrel_shifter.vhd
# use VHDL_SOURCES for VHDL files

# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
# MODULE is the basename of the Python test file
formal :
		sby --yosys "yosys -m ghdl" -f barrel_shifter.sby

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim