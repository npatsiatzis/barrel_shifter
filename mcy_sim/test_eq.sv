
module miter 
    (
        input logic i_clk,
        input logic i_signed,
        input logic i_shift_left,
        input logic [4 : 0] i_shift_amt,
        input logic [31 : 0] i_data,
        output logic [31 : 0] o_data
	);

    wire ref_i_signed;
    wire ref_i_shift_left;
    wire [4 : 0] ref_i_shift_amt;
    wire [31 : 0] ref_i_data;
    wire [31 : 0] ref_o_data;
    wire uut_i_signed;
    wire uut_i_shift_left;
    wire [4 : 0] uut_i_shift_amt;
    wire [31 : 0] uut_i_data;
    wire [31 : 0] uut_o_data;

	reg f_past_valid;


	barrel_shifter  ref
	(
		.mutsel(1'b0),
		.i_clk  (i_clk),
		.i_signed(ref_i_signed),
		.i_shift_amt(ref_i_shift_amt),
		.i_shift_left(ref_i_shift_left),
		.i_data(ref_i_data),
		.o_data(ref_o_data)
	);

	barrel_shifter  uut
	(
		.mutsel(1'b0),
		.i_clk  (i_clk),
		.i_signed(uut_i_signed),
		.i_shift_amt(uut_i_shift_amt),
		.i_shift_left(uut_i_shift_left),
		.i_data(uut_i_data),
		.o_data(uut_o_data)
	);

	always @* begin
		assume_data : assume (ref_i_data == uut_i_data);
		assume_shift_amt : assume (ref_i_shift_amt == uut_i_shift_amt);
		assume_shift_left : assume (ref_i_shift_left == uut_i_shift_left);
		assume_signed : assume (ref_i_signed == uut_i_signed);
	end

	initial begin
		f_past_valid <= 1'b0;
	end
	
	always @(posedge i_clk) begin
		f_past_valid <= 1'b1;
			// assert_valid : assert (ref_o_valid == uut_o_valid);
			if(f_past_valid)
				assert_C : assert (ref_o_data == uut_o_data);
	end
endmodule
