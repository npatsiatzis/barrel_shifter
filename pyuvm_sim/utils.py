from cocotb.triggers import Timer,RisingEdge,ClockCycles
from cocotb.queue import QueueEmpty, Queue
import cocotb
import enum
import random
from cocotb_coverage import crv 
from cocotb_coverage.coverage import CoverCross,CoverPoint,coverage_db
from pyuvm import utility_classes



class FifoBfm(metaclass=utility_classes.Singleton):
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
        # f_wr_done = 0
        while True:
            # f_wr_done = self.dut.f_wr_done.value
            await RisingEdge(self.dut.i_clk)
            data_tuple = (self.dut.i_signed.value,self.dut.i_shift_left.value,self.dut.i_shift_amt.value,self.dut.i_data.value)
            self.data_mon_queue.put_nowait(data_tuple)
    

            # if((self.dut.f_wr_done.value ==1 and f_wr_done == 0) or (self.dut.f_wr_done.value ==1 and f_wr_done == 1)):
            #     data = self.dut.f_data.value
            #     self.data_mon_queue.put_nowait(data)

    async def result_mon_bfm(self):
        # f_rd_done = 0 
        await RisingEdge(self.dut.i_clk)
        while True:
            # f_rd_done = self.dut.f_rd_done.value
            await RisingEdge(self.dut.i_clk)
            self.result_mon_queue.put_nowait((self.dut.o_data.value))
            # if((self.dut.f_rd_done.value == 1 and f_rd_done == 0) or (self.dut.f_rd_done.value == 1 and f_rd_done == 1)):
                # self.result_mon_queue.put_nowait((self.dut.o_data.value))


    def start_bfm(self):
        cocotb.start_soon(self.driver_bfm())
        cocotb.start_soon(self.data_mon_bfm())
        cocotb.start_soon(self.result_mon_bfm())