`default_nettype none

module barrel_shifter
    (
        input logic i_clk,
        input logic i_signed,
        input logic i_shift_left,
        input logic [4 : 0] i_shift_amt,
        input logic [31 : 0] i_data,
        output logic [31 : 0] o_data
    );

    `ifdef ICARUS
        logic [15 : 0] c_fill = 0;
    `else
        const logic [15 : 0] c_fill = 0;
    `endif
    
    always_ff @(posedge i_clk) begin : proc_shift
        logic [31 : 0] r_tmp;
        if (i_shift_left) begin
            for (int i=0;i<=31;i++) begin
                r_tmp[i] = i_data[31 - i];
            end
        end else if (i_signed) begin
            if (i_data[$high(i_data)])
                r_tmp = ~i_data;
            else
                r_tmp = i_data;
        end else
            r_tmp = i_data;

        case (i_shift_amt[4])
            1'b0 :
                r_tmp = r_tmp;
            default :
                r_tmp = {c_fill, r_tmp[31 : 16]};
        endcase

        case (i_shift_amt[3 : 2])
            2'b00 :
                r_tmp = r_tmp;
            2'b01 :
                r_tmp = {c_fill[3 : 0], r_tmp[31 : 4]};
            2'b10 :
                r_tmp = {c_fill[7 : 0], r_tmp[31 : 8]};
            default :
                r_tmp = {c_fill[11 : 0], r_tmp[31 : 12]};
        endcase

        case (i_shift_amt[1 : 0])
            2'b00 :
                r_tmp = r_tmp;
            2'b01 :
                r_tmp = {c_fill[0], r_tmp[31 : 1]};
            2'b10 :
                r_tmp = {c_fill[1 : 0], r_tmp[31 : 2]};
            default :
                r_tmp = {c_fill[2 : 0], r_tmp[31 : 3]};
        endcase

        if (i_shift_left) begin
            for (int i=0;i<=31;i++) begin
                o_data[i] <= r_tmp[31 - i];
            end
        end else if (i_signed)
            if (i_data[$high(i_data)])
                o_data <= ~r_tmp;
            else
                o_data <= r_tmp;
        else
            o_data <= r_tmp;
    end

    `ifdef WAVEFORM
        initial begin
            // Dump waves
            $dumpfile("dump.vcd");
            $dumpvars(0, barrel_shifter);
        end
    `endif


                        /*          ######################      */
                        /*          Assertions && Coverage      */
                        /*          ######################      */

    `ifdef FORMAL
        check_SRA : assert property (@(posedge i_clk) i_signed && !i_shift_left |=> signed'(o_data) == (signed'($past(i_data)) >>> $past(i_shift_amt)));
        check_SRL : assert property (@(posedge i_clk) !i_signed && !i_shift_left |=> o_data == $past(i_data) >> $past(i_shift_amt));
        check_SLA_SLL : assert property (@(posedge i_clk) i_shift_left |=> o_data == $past(i_data) << $past(i_shift_amt));
    `endif
endmodule : barrel_shifter
