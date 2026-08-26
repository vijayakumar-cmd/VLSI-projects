# VLSI Design Portfolio Projects

This repository contains industry-grade RTL (Register Transfer Level) design projects demonstrating advanced digital design and verification concepts.

## 📋 Projects

### 1. **UART Transmitter & Receiver (Full-Duplex)**
A complete, synthesizable UART communication system with independent TX and RX modules.

**Key Features:**
- Full-duplex communication (simultaneous TX/RX)
- Configurable baud rates via clock divider
- Independent state machines for TX and RX
- Proper synchronous reset and clock domain handling
- 8-bit data, 1 stop bit, optional parity
- Comprehensive self-checking testbench
- Ready for synthesis with Xilinx/Altera/Cadence tools

**Design Complexity:** Beginner to Intermediate  
**Files:** See `uart/` directory

---

## 🛠️ Tools & Environment

- **HDL:** SystemVerilog / Verilog
- **Simulation:** Icarus Verilog (iverilog) / VCS / Questasim
- **Waveform Viewer:** GTKWave
- **Synthesis:** Xilinx Vivado / Intel Quartus / Cadence Genus

---

## 📁 Directory Structure

```
VLSI-projects/
├── uart/
│   ├── rtl/
│   │   ├── uart_tx.sv          # UART Transmitter module
│   │   ├── uart_rx.sv          # UART Receiver module
│   │   └── uart_top.sv         # Top-level wrapper
│   ├── tb/
│   │   ├── uart_tb.sv          # Main testbench
│   │   └── uart_pkg.sv         # Testbench package (constants, tasks)
│   ├── docs/
│   │   ├── UART_ARCHITECTURE.md      # Design documentation
│   │   ├── UART_TIMING_DIAGRAM.txt   # Timing specifications
│   │   └── UART_VERIFICATION_PLAN.md # Verification strategy
│   ├── sim/
│   │   ├── run_sim.sh                # Simulation script
│   │   ├── compile.sh                # Compilation script
│   │   └── wave.gtkw                 # GTKWave save file
│   └── README.md                     # Project-specific README
└── docs/
    └── DESIGN_GUIDELINES.md          # RTL coding standards
```

---

## 🚀 Quick Start (UART Project)

```bash
cd uart

# Compile RTL and Testbench
./sim/compile.sh

# Run simulation
./sim/run_sim.sh

# View waveforms
gtkwave sim/uart_sim.vcd &
```

---

## 📚 Documentation

- **UART_ARCHITECTURE.md** - Detailed block diagrams, signal descriptions, FSM design
- **DESIGN_GUIDELINES.md** - RTL coding standards, best practices, synthesis tips

---

## 👤 Author
**Vijay Kumar**  
Digital Design & Verification Engineer  
Portfolio: VLSI Design Projects

---

## 📝 License
This project is open-source for educational and portfolio purposes.
