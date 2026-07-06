# Analog-to-Digital Converter (ADC)

**Status: Under Active Development**

## Overview

This project implements a modular Analog-to-Digital Converter (ADC) in MATLAB, converting analog signals (e.g., speech) into digital audio files (e.g., WAV). It explores both **digital signal processing (DSP) paradigms**, including gain-tracking, anti-aliasing filtering, sampling, quantization, SNR analysis, and fixed-point precision tradeoffs and **software engineering paradigms** such as object-oriented programming (OOP), code reusability, and modularity.

---

## Project Status

### Unit Tested Implementations
Signal Generator Object

Automatic Gain Control (AGC) Object

Anti-Aliasing Filter Object

     
### Planned / In Progress
Analog-to-Digital Converter ( Sampler + Bipolar Midtread Quantizer) Object

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
