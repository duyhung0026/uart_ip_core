# UART IP Core (Verilog)

> **Project Status: Still ongoing.**

`This design is provided for educational and reference purposes only. It may contain design errors, functional limitations, or deviations from the intended specifications, and has not been fully verified.`

`Warns: used AI models to write Verilog testbenchs, testplan and testcases for verification `

This project implements a UART IP Core using Verilog, following the
**Lattice UART IP User Guide** (FPGA-IPUG-02105, v1.5, IP v1.4.0) as a
design reference.

The main objective is to understand RTL design concepts and
implementation, including FSM design and baud rate generation.


## Modules

  -----------------------------------------------------------------------------------------------
  File                    Module                  Description
  ----------------------- ----------------------- -----------------------------------------------
  `uart_tx.v`             `baud_gen`              Generates a 16x baud rate tick from the Divisor
                                                  Latch Register (DLR).

  `uart_tx.v`             `uart_tx`               UART transmitter using an FSM:
                                                  `IDLE → LOAD → START → DATA → PARITY → STOP`.

  `uart_tx_tb.v`          `uart_tx_tb`            Testbench for `baud_gen` and `uart_tx`.
  -----------------------------------------------------------------------------------------------

### UART TX Features

-   Configurable character length: 5, 6, 7, or 8 bits
    (`char_len_sel_i`).
-   Even, odd, and stick parity support (`parity_en_i`,
    `even_parity_sel_i`, `stick_parity_en_i`).
-   Configurable stop bits: 1, 1.5, or 2 bits (`stop_bit_ctrl_i`).
    -   `0`: 1 stop bit.
    -   `1`: 1.5 stop bits for 5-bit characters; otherwise, 2 stop bits.
-   Break control (`break_ctrl_en_i`), which forces `txd_o` low.
-   LSR-related status signals: `thr_empty_o` and `xmitr_empty_o`.
-   Additional status signal: `tx_ready_n_o`.
-   Configuration parameters are latched in the `S_LOAD` state.

### Baud Rate Generator

The `baud_gen` module uses the divisor:

``` text
divisor = {dlr_msb_i, dlr_lsb_i}
```

It generates a 16x baud rate tick with a period of approximately:

``` text
divisor / 16 clock cycles
```

Example:

-   Clock frequency: 100 MHz
-   Baud rate: 9600
-   Divisor: 10417 (`0x28B1`)
-   Tick period: 6510 ns

The tick period has been verified through simulation.

## Design Conventions

Based on the Lattice specification:

-   `_i`: Input signal.
-   `_o`: Output signal.
-   `_n`: Active-low signal.
-   Reset: Asynchronous, active-low (`rst_n_i`).

## Simulation

### Vivado (XSim)

1.  Add `uart_tx.v` and `uart_tx_tb.v` to the Vivado project.
2.  Set `uart_tx_tb` as the simulation top module.
3.  Run `run all`.
4.  Observe the `txd_o` waveform.

The testbench transmits the following frames:

  Data       Character Length Parity     Stop Bits
  -------- ------------------ -------- -----------
  `0xA5`               8 bits None               1
  `0x15`               5 bits None               1
  `0x00`               8 bits None               1

## Known Issue
**Parity calculation and character length**

In `uart_tx`, `data_mask` is calculated using `last_bit_idx`. However,
`last_bit_idx` is updated at the end of `S_LOAD`, while `parity_bit_reg`
is calculated earlier in the same state.

As a result, parity may be incorrect when the character length changes
between frames, or when the first frame after reset uses a character
length shorter than 8 bits with non-zero upper data bits.

The testbench currently does not enable parity, so this issue has not
been covered by the existing simulation.

## Reference
-   Lattice Semiconductor, *UART IP User Guide*, FPGA-IPUG-02105

