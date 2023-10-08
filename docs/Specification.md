## Requirements Specification


### 1. SCOPE

1. **Scope**

   This document establishes the requirements for an Intellectual Property (IP) that provides a 32-bit barrel shifter function.
1. **Purpose**
 
   These requirements shall apply to a barrel shifter core with a simple interface for inclusion as a component.
1. **Classification**
    
   This document defines the requirements for a hardware design.


### 2. DEFINITIONS

1. **Barrel Shifter**

   A barrel shifter is a digital circuit that can shift a word by any number of bits using only combinational logic.
   

### 3. APPLICABLE DOCUMENTS 

1. **Government Documents**

   None
1. **Non-government Documents**

   None


### 4. ARCHITECTURAL OVERVIEW

1. **Introduction**

   The barrel shifter component shall represent a design written in an HDL (VHDL and/or SystemVerilog) that can easily be        incorporateed into a larger design. The core shall include the following features : 
     1. Shift Left Logical (SLL) operation.
     1. Shift Left Arithmetic (SLA) operation.
     1. Shift Right Logical (SRL) operation.
     2. Shift Right Arithmetic (SRA) operation.

No particular interface will be used in the initial phase of this core for communicating with the processor/controller.

1. **System Application**
   
    The barrel shifter can be applied to a variety of system configurations. An example use case is to be used to transform data between an upstream producer and a downstream consumer.

### 5. PHYSICAL LAYER

1. i_data, input data to be shifted
1. signed, indicate whether input data should be treated as a signed number
5. shift_left, specify shift direction
6. shit_amt, specify amount of bits to shift the data
8. o_data, output data after bits are shifted
7. clk, system clock
8. rst, system reset, synchronous active high

### 6. PROTOCOL LAYER

A shift operation consists of the following information:
   
1. shift direction
2. how the input data is treated, unsigned or signed (logical or arithmetic shift)
3. shit amount
4. input data to be shifted. 

### 7. ROBUSTNESS

Does not apply.

### 8. HARDWARE AND SOFTWARE

1. **Parameterization**

   There will be no parameterization in the initial version of this core which will support all the shift operations for any 32-bit number.

 

1. **CPU interface**

   No particular CPU interface.


### 9. PERFORMANCE

1. **Frequency**
1. **Power Dissipation**
1. **Environmental**
 
   Does not apply.
1. **Technology**

   The design shall be adaptable to any technology because the design shall be portable and defined in an HDL.

### 10. TESTABILITY
None required.

### 11. MECHANICAL
Does not apply.
