# FIFO design notes

## Synchronous FIFO

The single-clock FIFO stores a binary write pointer and read pointer and maintains a word count. The count makes full and empty behavior correct for arbitrary positive depths, including depths that are not powers of two. Pointer wrap is explicitly handled at `DEPTH-1`.

## Asynchronous FIFO

The dual-clock FIFO uses an extra pointer bit to distinguish wraparound. Binary pointers are converted to Gray code before crossing clock domains. Each Gray pointer is synchronized through two registers in the receiving clock domain. Empty is detected when the next read Gray pointer equals the synchronized write Gray pointer. Full is detected when the next write Gray pointer equals the synchronized read pointer with its two wrap bits inverted.

The Gray-pointer full comparison requires a power-of-two depth and `ADDR_WIDTH >= 2`. The memory is inferred as a dual-clock memory; FPGA block-RAM inference may require device- or tool-specific attributes for a particular implementation.

`wr_level` and `rd_level` are local-domain occupancy estimates. They are not instantaneous global counts because the opposite pointer is delayed by synchronizer latency.
