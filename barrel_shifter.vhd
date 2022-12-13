--32-bit barrel shifter that can perform SRL,SRA,SLL/SLA
--by setting the i_signed, i_shift_left input ports accordingly

library ieee;
use ieee.std_logic_1164.all;

entity barrel_shifter is
	port(
		i_clk : in std_ulogic;
		i_signed : in std_ulogic;
		i_shift_left : in std_ulogic;
		i_shift_amt : in std_ulogic_vector(4 downto 0);
		i_data : in std_ulogic_vector(31 downto 0);
		o_data : out std_ulogic_vector(31 downto 0));
end barrel_shifter;

architecture rtl of barrel_shifter is
	constant c_fill : std_ulogic_vector(15 downto 0) := (others => '0');		--fill with 0s for SR
begin
	prepare_signed : process(i_clk)
		variable r_tmp : std_ulogic_vector(31 downto 0) :=(others => '0');		--holds the data under constr.
	begin
		if(rising_edge(i_clk)) then
			if(i_shift_left = '1') then
				for i in 0 to 31 loop 			--flip each half and swap them
					r_tmp(i) := i_data(31-i);	--required to perform SLL with
				end loop;						--with same logic as with SRL

			elsif(i_signed = '1') then			--negate every bit
				if(i_data(i_data'high) = '1') then		--required to perform SRA
					r_tmp := not i_data;		--with same logic as with SRL
				else   							--if extension with 1s is required
					r_tmp := i_data;
				end if;
			else
				r_tmp := i_data;
			end if;

			--same shifter irrespective of shift l/r signed/unsiged
			--implements SRL  for the 32-bit case.
			--differentiations per configuration taken care of by negating bits (SRA)
			-- and flipping & swapping (SLL)
			case i_shift_amt(4) is
				when '0' => r_tmp := r_tmp;
				when others =>  r_tmp := c_fill(15 downto 0) & r_tmp(31 downto 16);
			end case;

			case i_shift_amt(3 downto 2) is 
				when "00" => r_tmp := r_tmp;
				when "01" => r_tmp := c_fill(3 downto 0) & r_tmp(31 downto 4);
				when "10" => r_tmp := c_fill(7 downto 0) & r_tmp(31 downto 8);
				when others => r_tmp := c_fill(11 downto 0) & r_tmp(31 downto 12);
			end case;

			case i_shift_amt(1 downto 0) is 
				when "00" => r_tmp := r_tmp;
				when "01" => r_tmp := c_fill(0) & r_tmp(31 downto 1);
				when "10" => r_tmp := c_fill(1 downto 0) & r_tmp(31 downto 2);
				when others => r_tmp := c_fill(2 downto 0) & r_tmp(31 downto 3);
			end case;

			--after essentially performing SRL
			--revert back all transformations
			--to obtain correct result of each configuration
			if(i_shift_left = '1') then
				for i in 0 to 31 loop 
					o_data(i) <= r_tmp(31-i);
				end loop;
			elsif(i_signed = '1') then
				if(i_data(i_data'high) = '1') then
					o_data <= not r_tmp;
				else
					o_data <= r_tmp;
				end if;
			else
				o_data <= r_tmp;
			end if;
		end if;
	end process; -- prepare_signed
end rtl;