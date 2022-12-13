import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer,RisingEdge,FallingEdge,ClockCycles,ReadOnly
from cocotb.result import TestFailure
import random
from cocotb_coverage.coverage import CoverCross,CoverPoint,coverage_db
import numpy as np

full = False

def sum_pow_2(length,vector):
	sum = 0
	bin_vec = bin(vector)
	if((len(bin_vec) == 34) and (bin_vec[2] == '1')):
		for i in range(length):
			sum += 2**(31-i)
	return sum	

# #Callback functions to capture the bin content showing
def notify_full():
	global full
	full = True



# at_least = value is superfluous, just shows how you can determine the amount of times that
# a bin must be hit to considered covered
@CoverPoint("top.signed",xf = lambda x : x.i_signed.value, bins = [True,False], at_least=1)
@CoverPoint("top.shift_left",xf = lambda x : x.i_shift_left.value, bins = [True,False],at_least=1)
@CoverPoint("top.shift_amt",xf = lambda x : x.i_shift_amt.value,bins = list(range(2**5)),at_least=1)
@CoverPoint("top.i_data",xf = lambda x : x.i_data.value,bins = list(range(2**10)),at_least=1)
@CoverCross("top.shift_amt_X_i_data", items = ["top.shift_amt","top.i_data"], at_least=1)
def number_cover(dut):
	pass

async def init(dut,cycles=1):

	dut.i_signed.value = 0 
	dut.i_shift_left.value = 0
	dut.i_shift_amt.value = 0
	dut.i_data.value = 0

	await ClockCycles(dut.i_clk,cycles)
	dut._log.info("the core was initialized")

@cocotb.test()
async def test(dut):
	expected_value = np.uint32(0)
	cocotb.start_soon(Clock(dut.i_clk, 10, units="ns").start())

	await init(dut,5)	

	while (full != True):	
		signed = random.randint(0,1)
		shift_left = random.randint(0,1)
		shift_amt = random.randint(0,2**5-1)
		data = random.randint(0,2**10-1)

		dut.i_signed.value = signed
		dut.i_shift_left.value = shift_left
		dut.i_shift_amt.value = shift_amt
		dut.i_data.value = data
		
		await RisingEdge(dut.i_clk)

		if(shift_left == 1):
			expected_value = data << shift_amt
		else:
			expected_value = data >> shift_amt
			if(signed ==1):
				expected_value = expected_value + sum_pow_2(shift_amt,data)

		await RisingEdge(dut.i_clk)
		assert not (np.uint32(expected_value) != int(dut.o_data.value)),"Different expected to actual data, signed"

		coverage_db["top.i_data"].add_threshold_callback(notify_full, 100)
		number_cover(dut)
