from cocotb.triggers import Timer,RisingEdge,FallingEdge,ClockCycles,ReadOnly
from cocotb.queue import QueueEmpty, Queue
import cocotb
from cocotb.result import TestFailure
import enum
import random
from cocotb_coverage import crv 
from cocotb_coverage.coverage import CoverCross,CoverPoint,coverage_db,CoverCheck
from cocotb.binary import BinaryValue
from pyuvm import utility_classes

class BarrelShiftBfm(metaclass=utility_classes.Singleton):
    def __init__(self):
        self.dut = cocotb.top
        self.driver_queue = Queue(maxsize=1)
        self.data_mon_queue = Queue(maxsize=0)
        self.result_mon_queue = Queue(maxsize=0)

    async def send_data(self, data):
        await self.driver_queue.put(data)

    async def get_data(self):
        data = await self.data_mon_queue.get()
        return data

    async def get_result(self):
        result = await self.result_mon_queue.get()
        return result

    async def reset(self):
        await RisingEdge(self.dut.i_clk)
        self.dut.i_signed.value = 0
        self.dut.i_shift_left.value = 0
        self.dut.i_shift_amt.value = 0
        self.dut.i_data.value = 0 
        await ClockCycles(self.dut.i_clk,5)

    async def driver_bfm(self):
        while True:
            await RisingEdge(self.dut.i_clk)
            try:
                (i_signed,i_shift_left,i_shift_amt,i_data) = self.driver_queue.get_nowait()
                self.dut.i_signed.value = i_signed
                self.dut.i_shift_left.value = i_shift_left
                self.dut.i_shift_amt.value = i_shift_amt
                self.dut.i_data.value = i_data
            except QueueEmpty:
                pass

    async def data_mon_bfm(self):
        while True:
            await RisingEdge(self.dut.i_clk)
            data_tuple = (self.dut.i_signed.value,self.dut.i_shift_left.value,self.dut.i_shift_amt.value,self.dut.i_data.value)
            self.data_mon_queue.put_nowait(data_tuple)

    async def result_mon_bfm(self):
        await RisingEdge(self.dut.i_clk)
        while True:
            await RisingEdge(self.dut.i_clk)
            self.result_mon_queue.put_nowait((self.dut.o_data.value))


    def start_bfm(self):
        cocotb.start_soon(self.driver_bfm())
        cocotb.start_soon(self.data_mon_bfm())
        cocotb.start_soon(self.result_mon_bfm())




class AssertionsCheck(metaclass=utility_classes.Singleton):
    def __init__(self):
        self.dut = cocotb.top
        self.assertion1 = Assertion_SLL_EQ_SLA()
        # self.assertion2 = Assertion_not_i_valid_impl_stable_o_C()
  
    def start_assertions(self):
        cocotb.start_soon(self.assertion1.assertion_mon_shift_left_ant())
        # cocotb.start_soon(self.assertion2.assertion_mon_not_valid_ant())


class Assertion_SLL_EQ_SLA(metaclass=utility_classes.Singleton):
    def __init__(self):
        self.dut = cocotb.top
        # for i_valid |=> o_valid
        self.cycles_to_count_till_consequent_valid = 1
        self.cnt_cycles_since_antecedent_valid = 0
        self.orig_data = 0
        self.shift_amt = 0
        self.expected_value = 0

    # assert property (@(posedge i_clk) i_shift_left |=> (o_data == unsigned'($past(i_data) << $past(i_shift_amt));
    @CoverCheck(
        "assertion.shift_left IMPL_NO_OVERLAP (o_data == unsigned'($past(data) SHIFT_LEFT_L $past(shamt))",
        f_fail = lambda x,expected_value : int(x.o_data.value) != expected_value,
        f_pass = lambda x,expected_value : True
    )
    def test_SLL_SLA(self,dut,expected_value):
        pass

    def assert_callback(self):
        raise TestFailure("Assertion failed!")

    async def assertion_mon_shift_left_ant(self):
        while True:
            if(self.cnt_cycles_since_antecedent_valid == self.cycles_to_count_till_consequent_valid):
                self.cnt_cycles_since_antecedent_valid = 0

                self.test_SLL_SLA(self.dut,self.expected_value)
                coverage_db["assertion.shift_left IMPL_NO_OVERLAP (o_data == unsigned'($past(data) SHIFT_LEFT_L $past(shamt))"].add_bins_callback(self.assert_callback, "FAIL")
            if(int(self.dut.i_shift_left.value) == 1):
                self.cnt_cycles_since_antecedent_valid += 1

                self.orig_data = self.dut.i_data
                self.shift_amt = self.dut.i_shift_amt

                self.orig_data = BinaryValue(value=str(self.orig_data),bigEndian=False ,n_bits=32,binaryRepresentation=0)
                self.orig_data = self.orig_data.integer
                self.expected_value = int(self.orig_data) << int(self.shift_amt)
                self.expected_value = self.expected_value & ((2**32) -1)

            await RisingEdge(self.dut.i_clk)