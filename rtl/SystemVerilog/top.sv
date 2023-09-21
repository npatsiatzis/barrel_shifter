`include "assertion.sv"
module top
    (
        input logic i_clk,
        input logic i_signed,
        input logic i_shift_left,
        input logic [4 : 0] i_shift_amt,
        input logic [31 : 0] i_data,
        output logic [31 : 0] o_data
    );

    barrel_shifter  DUT 
    (
    	.i_clk,
    	.i_signed,
    	.i_shift_left,
    	.i_shift_amt,
    	.i_data,
    	.o_data
	);

    // Note: Verilator only ssupports bind to a target module name, NOT to an instance path.
	bind barrel_shifter assertion inst
    (
    	.i_clk,
    	.i_signed,
    	.i_shift_left,
    	.i_shift_amt,
    	.i_data,
    	.o_data
	);
endmodule
