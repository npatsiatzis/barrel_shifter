![example workflow](https://github.com/npatsiatzis/barrel_shifter/actions/workflows/main.yml/badge.svg)
![example workflow](https://github.com/npatsiatzis/barrel_shifter/actions/workflows/coverage.yml/badge.svg)

### barrel-shifter RTL implementation


- 32-bits barrel shifter
- performs SRL, SRA, SLL/SLA operations

-- CoCoTB testbench for functional verification
    - $ make
- Coverage-driven test generation
- Achieve full point coverage for inputs, outputs and cross coverage
- CoCoTB-test unit testing to exercise the CoCoTB tests across a range of values for the generic parameters
    - $  SIM=ghdl pytest -n auto -o log_cli=True --junitxml=test-results.xml --cocotbxml=test-cocotb.xml



