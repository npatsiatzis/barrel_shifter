# Makefile

# defaults
SIM ?= ghdl
# SIM ?= modelsim
TOPLEVEL_LANG ?= vhdl

ifeq ($(SIM),ghdl)
    EXTRA_ARGS += --std=08
    SIM_ARGS += --wave=wave.ghw
else ifneq ($(filter $(SIM),questa modelsim riviera activehdl),)
    COMPILE_ARGS += -2008
endif

VHDL_SOURCES += $(PWD)/barrel_shifter.vhd
# use VHDL_SOURCES for VHDL files

# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
# MODULE is the basename of the Python test file


test:
		rm -rf sim_build
		$(MAKE) sim MODULE=testbench TOPLEVEL=barrel_shifter

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim