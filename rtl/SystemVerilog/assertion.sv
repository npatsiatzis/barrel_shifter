module assertion
    (
        input logic i_clk,
        input logic i_signed,
        input logic i_shift_left,
        input logic [4 : 0] i_shift_amt,
        input logic [31 : 0] i_data,
        input logic [31 : 0] o_data
    );

        check_SRA : assert property (@(posedge i_clk) i_signed && !i_shift_left |=> signed'(o_data) == (signed'($past(i_data)) >>> $past(i_shift_amt)));
        check_SRL : assert property (@(posedge i_clk) !i_signed && !i_shift_left |=> o_data == $past(i_data) >> $past(i_shift_amt));
        check_SLA_SLL : assert property (@(posedge i_clk) i_shift_left |=> o_data == $past(i_data) << $past(i_shift_amt));
endmodule
