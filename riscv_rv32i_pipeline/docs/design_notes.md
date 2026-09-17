# Design notes

## Hazard policy

The core uses a static-not-taken predictor. A taken branch, JAL, or JALR is resolved in EX; the younger IF/ID and ID/EX instructions are flushed and `pc` is redirected. This gives a simple, deterministic two-instruction control-hazard penalty.

ALU results are forwarded directly from EX/MEM and MEM/WB. A load result is not available until MEM/WB, so a dependent instruction is held in IF/ID and a bubble is inserted into EX for one cycle. Register x0 is hardwired to zero.

## Timing-closure considerations

The critical path is generally the register-file read, forwarding muxes, ALU, and branch comparator in EX. For higher frequency, register the memory interfaces, split branch comparison from target generation, use a multiported register-file macro, and constrain the external memory timing. The supplied 100 MHz constraint is an integration starting point rather than a guaranteed timing result.

## Memory model

The core assumes combinational instruction and load-data returns and writes stores on the clock edge. A production implementation should add ready/valid handshakes, byte/halfword load-store support, alignment checks, and a bus/cache interface.
