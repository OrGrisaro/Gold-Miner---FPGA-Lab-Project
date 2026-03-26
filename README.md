# Gold Miner - FPGA 2D Arcade Game

## Overview
A complete implementation of the classic "Gold Miner" game in an arcade style, written in SystemVerilog and deployed on the DE-10 board. 

The project involves a full hardware-software co-design, including a custom VGA controller for graphics, an FSM-based game logic, collision detection, and peripheral support for control and audio.

---

## Repository Structure
To make it easy to view the core work, the repository is structured as follows:

* 📁 **docs/**: Contains the full Project Book and Final Presentation (PDF).
* 📁 **hw/**: The entire hardware implementation.
  * 📁 **top/**: Top-level Quartus project files (`.qpf`, `.qsf`).
  * 📁 **rtl/**: Core source code (`.v`, `.sv`), including submodules for VGA, Audio, and Keyboard.
  * 📁 **mem/**: Graphics and data assets (`.hex`, `.mif`).
  * 📁 **constraints/**: Pin mapping (`.tcl`) and timing (`.sdc`) constraints.
  * 📁 **signaltap/**: SignalTap debug configurations for on-chip verification.

---

## Documentation & Presentation
* [Project Book (PDF)](added to files)
* [Final Presentation (PPTX)](added to files)

---

## System Architecture
<img width="1120" height="550" alt="image" src="https://github.com/user-attachments/assets/d10e8467-b5ad-4722-8697-291796f392ea" />

---

## Project Specifications
* **Target Device:** [DE-10 Chip Model]
* **Clock Speed:** 50MHz internal clock, with a custom `31.5MHz` pixel clock for VGA.
* **Graphics:** 640x480 resolution at 60Hz.

---

## Highlights for Potential Employers
* **SignalTap On-Chip Debugging:** Used advanced debugging techniques with dedicated SignalTap files included (`hw/signaltap/`).
* **Custom Peripherals:** Developed interface modules for PS/2 keyboard and audio output.
* **FSM-based Game Logic:** Implemented complex game state machines, including player movement, gold grabbing, and enemy interactions.
* **Custom Memory Management:** Utilized dual-port RAM for graphic asset storage.

## Screenshots / Video Demo
*(Drag and drop a cool screenshot or link to a YouTube video demo here).*
