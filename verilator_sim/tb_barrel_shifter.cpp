// Verilator Example
#include <stdlib.h>
#include <iostream>
#include <cstdlib>
#include <memory>
#include <verilated.h>
#include <verilated_vcd_c.h>
#include "Vbarrel_shifter.h"
// #include "Vbarrel_shifter_synchronous_fifo.h"   //to get parameter values, after they've been made visible in SV


#define MAX_SIM_TIME 300
#define VERIF_START_TIME 7
#define COVERAGE_BITS 10
vluint64_t sim_time = 0;
vluint64_t posedge_cnt = 0;

// input interface transaction item class
class InTx {
    private:
    public:
        uint32_t i_signed;
        uint32_t i_shift_left;
        uint32_t i_shift_amt;
        uint32_t i_data;
};


// output interface transaction item class
class OutTx {
    public:
        uint32_t o_data;
};

//in domain Coverage
class InCoverage{
    private:
        std::set <uint32_t> in_cvg;
    
    public:
        void write_coverage(InTx *tx){
            // std::tuple<uint32_t,uint32_t> t;
            // t = std::make_tuple(tx->A,tx->B);
            // in_cvg.insert(t);
            in_cvg.insert(tx->i_data);
        }

        bool is_covered(uint32_t A){
            // std::tuple<uint32_t,uint32_t> t;
            // t = std::make_tuple(A,B);            
            // return in_cvg.find(t) == in_cvg.end();
            return in_cvg.find(A) == in_cvg.end();
        }
};

//out domain Coverage
class OutCoverage {
    private:
        std::set <uint32_t> coverage;
        int cvg_size = 0;

    public:
        void write_coverage(OutTx* tx){
            coverage.insert(tx->o_data); 
            cvg_size++;
        }

        bool is_full_coverage(){
            return cvg_size == (1 << COVERAGE_BITS);
            // return coverage.size() == (1 << (Vbarrel_shifter_synchronous_fifo::G_WIDTH));
        }
};


// ALU scoreboard
class Scb {
    private:
        std::deque<InTx*> in_q;
        
    public:
        // Input interface monitor port
        void writeIn(InTx *tx){
            // Push the received transaction item into a queue for later
            in_q.push_back(tx);
        }

        // Output interface monitor port
        void writeOut(OutTx* tx){
            // We should never get any data from the output interface
            // before an input gets driven to the input interface
            if(in_q.empty()){
                std::cout <<"Fatal Error in AluScb: empty InTx queue" << std::endl;
                exit(1);
            }

            // Grab the transaction item from the front of the input item queue
            InTx* in;
            in = in_q.front();
            in_q.pop_front();
            int expected_value  = 0;

            if (in->i_shift_left == 1) {
                expected_value = in->i_data << in->i_shift_amt;
            } else {
                expected_value = in->i_data >> in->i_shift_amt;

            }

            if(expected_value != tx->o_data){
                std::cout << "Test Failure!" << std::endl;
                std::cout << "Expected : " <<  expected_value << std::endl;
                std::cout << "Got : " << tx->o_data << std::endl;
                exit(1);
            } else {
                std::cout << "Test PASS!" << std::endl;
                std::cout << "Expected : " <<  expected_value << std::endl;
                std::cout << "Got : " << tx->o_data << std::endl; 
            }

            // As the transaction items were allocated on the heap, it's important
            // to free the memory after they have been used
            delete in;    //input monitor transaction
            delete tx;    //output monitor transaction
        }
};

// interface driver
class InDrv {
    private:
        // Vbarrel_shifter *dut;
        std::shared_ptr<Vbarrel_shifter> dut;
    public:
        InDrv(std::shared_ptr<Vbarrel_shifter> dut){
            this->dut = dut;
        }

        void drive(InTx *tx){
            // we always start with in_valid set to 0, and set it to
            // 1 later only if necessary
            // dut->i_valid = 0;

            // Don't drive anything if a transaction item doesn't exist
            if(tx != NULL){
                dut->i_data = tx->i_data;
                dut->i_shift_left = tx->i_shift_left;
                dut->i_signed = tx->i_signed;
                dut->i_shift_amt = tx->i_shift_amt;
                // Release the memory by deleting the tx item
                // after it has been consumed
                delete tx;
            }
        }
};

// input interface monitor
class InMon {
    private:
        // Vbarrel_shifter *dut;
        std::shared_ptr<Vbarrel_shifter> dut;
        // Scb *scb;
        std::shared_ptr<Scb>  scb;
        // InCoverage *cvg;
        std::shared_ptr<InCoverage> cvg;
    public:
        InMon(std::shared_ptr<Vbarrel_shifter> dut, std::shared_ptr<Scb>  scb, std::shared_ptr<InCoverage> cvg){
            this->dut = dut;
            this->scb = scb;
            this->cvg = cvg;
        }

        void monitor(){
            // if(dut->i_wr == 1 && dut->o_full == 0){
            InTx *tx = new InTx();
            tx->i_data = dut->i_data;
            tx->i_signed = dut->i_signed;
            tx->i_shift_left = dut->i_shift_left;
            tx->i_shift_amt = dut->i_shift_amt;

            // then pass the transaction item to the scoreboard
            scb->writeIn(tx);
            cvg->write_coverage(tx);
            // }
        }
};

// ALU output interface monitor
class OutMon {
    private:
        // Vbarrel_shifter *dut;
        std::shared_ptr<Vbarrel_shifter> dut;
        // Scb *scb;
        std::shared_ptr<Scb> scb;
        // OutCoverage *cvg;
        std::shared_ptr<OutCoverage> cvg;
    public:
        OutMon(std::shared_ptr<Vbarrel_shifter> dut, std::shared_ptr<Scb> scb, std::shared_ptr<OutCoverage> cvg){
            this->dut = dut;
            this->scb = scb;
            this->cvg = cvg;
        }

        void monitor(){
                
            OutTx *tx = new OutTx();
            tx->o_data = dut->o_data;

            // then pass the transaction item to the scoreboard
            scb->writeOut(tx);
            cvg->write_coverage(tx);
            // }
        }
};

//sequence (transaction generator)
// coverage-driven random transaction generator
// This will allocate memory for an InTx
// transaction item, randomise the data, until it gets
// input values that have yet to be covered and
// return a pointer to the transaction item object
class Sequence{
    private:
        InTx* in;
        // InCoverage *cvg;
        std::shared_ptr<InCoverage> cvg;
    public:
        Sequence(std::shared_ptr<InCoverage> cvg){
            this->cvg = cvg;
        }

        InTx* genTx(){
            in = new InTx();
            // std::shared_ptr<InTx> in(new InTx());
            // if(rand()%5 == 0){
            in->i_data = rand() % (1 << 31);  
            in->i_shift_left = rand() % 2;
            in->i_signed = rand() % 2;  
            in->i_shift_amt = rand() % 8;

            while(cvg->is_covered(in->i_data) == false){
                in->i_data = rand() % (1 << 31);   
            }
            return in;
            // } else {
            //     return NULL;
            // }
        }
};


// void dut_reset (std::shared_ptr<Vbarrel_shifter> dut, vluint64_t &sim_time){
//     dut->i_rst = 0;
//     if(sim_time >= 3 && sim_time < 6){
//         dut->i_rst = 1;
//     }
// }

int main(int argc, char** argv, char** env) {
    srand (time(NULL));
    Verilated::commandArgs(argc, argv);
    // Vbarrel_shifter *dut = new Vbarrel_shifter;

    std::shared_ptr<VerilatedContext> contextp{new VerilatedContext};
    std::shared_ptr<Vbarrel_shifter> dut(new Vbarrel_shifter{contextp.get(), "TOP"});

    // std::shared_ptr<Vbarrel_shifter> dut(new Vbarrel_shifter);

    Verilated::traceEverOn(true);
    VerilatedVcdC *m_trace = new VerilatedVcdC;
    dut->trace(m_trace, 5);
    m_trace->open("waveform.vcd");

    InTx   *tx;

    // Here we create the driver, scoreboard, input and output monitor and coverage blocks
    std::unique_ptr<InDrv> drv(new InDrv(dut));
    std::shared_ptr<Scb> scb(new Scb());
    std::shared_ptr<InCoverage> inCoverage(new InCoverage());
    std::shared_ptr<OutCoverage> outCoverage(new OutCoverage());
    std::unique_ptr<InMon> inMon(new InMon(dut,scb,inCoverage));
    std::unique_ptr<OutMon> outMon(new OutMon(dut,scb,outCoverage));
    std::unique_ptr<Sequence> sequence(new Sequence(inCoverage));

    while (outCoverage->is_full_coverage() == false) {
        // dut_reset(dut, sim_time);
        dut->i_clk ^= 1;
        dut->eval();

        m_trace->dump(sim_time);
        sim_time++;

        // Do all the driving/monitoring on a positive edge
        if (dut->i_clk == 1){

            if (sim_time >= VERIF_START_TIME) {
                // Generate a randomised transaction item 
                // tx = rndInTx(inCoverage);
                tx = sequence->genTx();

                // Pass the generated transaction item in the driver
                //to convert it to pin wiggles
                //operation similar to than of a connection between
                //a sequencer and a driver in a UVM tb
                drv->drive(tx);

                // Monitor the input interface
                // also writes recovered transaction to
                // input coverage and scoreboard
                inMon->monitor();    

                // Monitor the output interface
                // also writes recovered result (out transaction) to
                // output coverage and scoreboard 
                if(sim_time > VERIF_START_TIME){
                    outMon->monitor();
                }
            }
        }
    }

    m_trace->close();  
    exit(EXIT_SUCCESS);
}
