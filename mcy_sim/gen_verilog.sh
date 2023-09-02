#!/bin/bash

yosys -m ghdl -p 'ghdl --std=08 barrel_shifter.vhd -e barrel_shifter; write_verilog barrel_shifter.v'