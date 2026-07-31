# Analog-to-Digital Signal Converter (ADC)

**Status: Under Active Development**

## Overview

This project implements a modular Analog-to-Digital Signal Converter (ADC) in MATLAB, converting analog signals (e.g., speech) into digital audio files (e.g., WAV). It explores two main areas:

1. **Digital Signal Processing (DSP) Paradigms:** Signal generation, filtering, gain-tracking, sampling, quantization, SNR analysis, and fixed-point precision tradeoffs.

2. **Software Engineering Paradigms:** Object-oriented programming (OOP), code reusability, and modularity.

Figure 1 shows the connecting modules and operation pipeline of the Analog-to-Digital-Signal Conversion.

<img width="1000" height="700" alt="image" src="https://github.com/user-attachments/assets/42c814f7-81ac-411c-afec-6ec54ebcbcb7" />

Figure 1: Complete DSP signal processing pipeline from analog simulation to decimated digital output.

---

## Project Status

### Current Implementation

Signal Generator Object

DC Removal (HPF) Object

Anti-Aliasing Filter Object

Automatic Gain Control (AGC) Object

ADC (Sampler + Bipolar Midtread Quantizer) Object
     
### Planned Work

FIR Digital Filter Object

Fixed-Point Analysis

Code Refactoring

Hardware-Oriented Optimization

- ---
## Current Implementation Demo Simulation & System Requirement

**Signal Generator Object:** An instance of this object generates the analog input signal to be converted to digital signal, consisting of a sinusoidal baseband signal (core data) & high - frequency interference signal, DC offset, and AWGN noise floor. Figure 2 shows the time domain and frequency domain of the input signal.

**Key Implementation Features:**

- **Non-Stationary Envelope Generation:** Rather than generating a static, continuous sine wave, the core baseband signal is amplitude-modulated using a custom envelope i.e. a Gaussian pulse followed by an exponential fade.

- **Real-World Transient Simulation:** This envelope creates a dynamic "burst and decay" profile, simulating the transient nature of real-world physical sources (such as human speech). This non-stationary behavior provides the necessary amplitude variance to rigorously test the downstream Automatic Gain Control (AGC) and quantization stages.

<img width="800" height="600" alt="image" src="https://github.com/user-attachments/assets/37987861-6749-4416-9b94-00becbbdb8df" />

Figure 2: Time and frequency domain representations of the synthesized noisy analog input signal.

**DC Removal (HPF) Object:** This module generates an instance of an N-order Butterworth High-Pass Filter (HPF) to eliminate unwanted DC bias from the incoming signal. In DSP, DC offsets are not universally detrimental; for example, unipolar quantizers rely on an injected DC offset to lift the analog signal entirely above zero. However, this simulation implements a bipolar mid-tread quantizer, which requires the signal to swing symmetrically across its zero-crossing. In this architecture, a residual DC offset restricts the dynamic range and severely degrades the quantizer's operational accuracy, making this HPF stage critical. A 4<sup>th</sup> order Butterworth HPF was used to remove the DC bias, yielding the centered signal shown in Figure 3.

**Key Implementation Features:**

- **Numerically Robust ZPK Formulation:** To mitigate floating-point inaccuracies and coefficient quantization errors common in higher-order filters, the filter coefficients are mathematically derived using a Zero-Pole-Gain (ZPK) formulation before being converted into the final transfer function polynomials.

**Anti-aliasing Filter (LPF):** This module generates an instance of an N-order Butterworth Low-Pass Filter (LPF) to strictly band-limit the incoming analog signal before it reaches the sampler. According to the Nyquist-Shannon sampling theorem, a system must sample at a rate at least twice the highest frequency present in the signal to prevent distortion. If frequencies exceeding the Nyquist limit ($f_s / 2$) enter the sampler, they "fold" back into the baseband, masquerading as lower frequencies. This phenomenon, known as aliasing, introduces irreversible inharmonic distortion that cannot be mathematically removed post-conversion. By aggressively attenuating the high-frequency interference generated in the input stage with a 6<sup>th</sup> order Butterworth LPF, this LPF guarantees a clean, alias-free conversion, as shown in Figure 3.

**Key Implementation Features:**

- **Numerically Robust ZPK Formulation:** To mitigate floating-point inaccuracies and coefficient quantization errors common in higher-order filters, the filter coefficients are mathematically derived using a Zero-Pole-Gain (ZPK) formulation before being converted into the final transfer function polynomials.

<img width="800" height="600" alt="image" src="https://github.com/user-attachments/assets/3f1b45d8-e47c-4eeb-ba47-b6635ca6a1e1" />

Figure 3: Clean analog signal after removal of DC bias and high-frequency interference.

**Feedforward Time-Varying Automatic Gain Control (AGC) With Noise Gate:** This module applies an AGC to dynamically adjust the gain of the incoming analog signal over time. Its primary function is to maintain the signal's amplitude integrity, ensuring it consistently utilizes the full dynamic range of the subsequent bipolar mid-tread quantizer without clipping. To prevent the system from amplifying the noise floor during quiet periods (such as fading audio), this module also integrates a Noise Gate. The noise gate dictates the AGC's behavior under low Signal-to-Noise Ratio (SNR) conditions:

- Signal Detection: When the target signal drops below a defined threshold and is barely present amidst the white noise, the gate activates.

- Gain Suspension: It explicitly stops the AGC from conditioning the analog signal, preventing the unwanted amplification of the noise floor.

- SNR Preservation: By freezing the gain during these periods, the noise gate effectively maximizes the SNR at the output of the quantizer.

**Key Implementation Features:**

- **Peak Envelope Detector:** Chosen over RMS detection to ensure deterministic quantizer safety. By tracking the true peak rather than energy averages, the system reacts instantaneously to transients, preventing hard-clipping and maintaining high fidelity signal mapping within the quantizer’s full-scale range.
- **Dynamic Thresholding:** Rather than relying on a hardcoded static value, the noise gate threshold is dynamically calculated based on the system's simulated noise floor parameter (Anf). This tightly couples the AGC to the input stage, ensuring the gate remains accurate even if the noise variance changes.
- **Leaky Integrator Smoothing:** The AGC employs leaky integrators for its attack and release times (Pgt_att and Pgt_rel). This guarantees smooth gain transitions, preventing the abrupt, unnatural "clicking" artifacts that occur when a noise gate opens or closes instantaneously.
- **Dynamic Headroom Mapping:** The upper and lower gain limits are directly parameterized to the full-scale voltage of the subsequent quantizer stage, ensuring amplitude scaling prior to quantization.

<img width="800" height="600" alt="image" src="https://github.com/user-attachments/assets/e60b091c-5913-46fb-b195-786fd76a944b" />

Figure 4: Time-domain response of the AGC, illustrating dynamic amplitude scaling and active noise gating during signal fade.

**Analog
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

Run current ADC module implementation:
```matlab
RunDemo
```
Run all unit tests:

```matlab
RunTests
```
Individual modules can be explored and run from the `Design/` folder.

---

## Author

**Damilola Awotunde**

MEng, Communications & Signal Processing - Western University | [LinkedIn](https://www.linkedin.com/in/damilola-awotunde) 
