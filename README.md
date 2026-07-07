# Analog-to-Digital Signal Converter (ADC)

**Status: Under Active Development**

## Overview

This project implements a modular Analog-to-Digital Signal Converter (ADC) in MATLAB, converting analog signals (e.g., speech) into digital audio files (e.g., WAV). It explores two main areas:

1. **Digital Signal Processing (DSP) Paradigms:** Signal generation, gain-tracking, filtering, sampling, quantization, SNR analysis, and fixed-point precision tradeoffs.

2. **Software Engineering Paradigms:** Object-oriented programming (OOP), code reusability, and modularity.

Figure 1 shows the connecting modules and operation pipeline of the Analog-to-Digital-Signal Conversion.

<img width="1000" height="700" alt="image" src="https://github.com/user-attachments/assets/42c814f7-81ac-411c-afec-6ec54ebcbcb7" />

Figure 1: Complete DSP signal processing pipeline from analog simulation to decimated digital output.

---

## Project Status

### Current Implementation

Signal Generator Object

DC Removal HPF

Anti-Aliasing Filter Object

Automatic Gain Control (AGC) Object
     
### Planned Work

Analog-to-Digital Converter (Sampler + Bipolar Midtread Quantizer) Object

FIR Digital Filter Object

Fixed-Point Analysis

Code Refactoring

Hardware-Oriented Optimization
               
- ---

## Repository Structure

```
Analog-to-Digital-Converter-ADC-/
|-- Design/       # Core module implementations
|-- Test/         # Unit tests for each module
|-- RunTests.m    # Test runner - executes all unit tests
```
 ---

## Requirements

MATLAB

Signal Processing Toolbox
                 
- ---

## How to Run

Clone the repository:

```bash
git clone https://github.com/DamiProject/Analog-to-Digital-Converter-ADC-.git
```

Open MATLAB and navigate to the project root directory.

Run all unit tests:

```matlab
RunTests
```
Individual modules can be explored and run from the `Design/` folder.

---

## Author

**Damilola Awotunde**

MEng, Communications & Signal Processing - Western University | [LinkedIn](https://www.linkedin.com/in/damilola-awotunde) 
