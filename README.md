# Analog-to-Digital Converter (ADC)

**Status: Under Active Development**

## Overview

This project implements a modular Analog-to-Digital Converter (ADC) in MATLAB, converting analog signals (e.g., speech) into digital audio files (e.g., MP3). It explores both **digital signal processing (DSP) paradigms** - including gain-tracking, anti-aliasing filtering, sampling, SNR analysis, and fixed-point precision tradeoffs - and **software engineering paradigms** such as object-oriented programming (OOP), code reusability, and modularity.

---

## Project Status

### Implemented (Unit Tested)
- Signal Generator
- - Automatic Gain Control (AGC)
  - - Anti-Aliasing Filter
    - - Sampling Module
     
      - ### Planned / In Progress
      - - Quantizer Module
        - - FIR Digital Filter
          - - Fixed-Point Analysis
            - - Code Refactoring
              - - Hardware-Oriented Optimization
               
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
                - **MATLAB** R2021a or later (recommended)
                - - **Signal Processing Toolbox**
                 
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
                  MEng, Communications & Signal Processing - Western University
                  [LinkedIn](https://www.linkedin.com/in/damilola-awotunde) - [GitHub](https://github.com/DamiProject)
