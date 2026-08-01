# Analog-to-Digital Signal Converter (ADC)

**Status: Under Active Development**

## Overview

This project implements a modular Analog-to-Digital Signal Converter (ADC) in MATLAB, converting analog signals (e.g., speech) into digital signals (e.g., WAV). It explores two main areas:

1. **Digital Signal Processing (DSP) Paradigms:** Signal generation, filtering, gain-tracking, sampling, quantization, SNR analysis, and fixed-point implementation.

2. **Software Engineering Paradigms:** Object-oriented programming (OOP), code reusability, and modularity.

<img width="1000" height="700" alt="image" src="https://github.com/user-attachments/assets/42c814f7-81ac-411c-afec-6ec54ebcbcb7" />

Figure 1: Complete DSP signal processing pipeline from analog simulation to decimated digital output.

---

## Project Status

### Current Implementation

- Signal Generator Object

- DC Removal (HPF) Object

- Anti-Aliasing Filter Object

- Automatic Gain Control (AGC) Object

- ADC (Sampler + Bipolar Midtread Quantizer) Object
     
### Planned Work

- FIR Digital Filter Object

- Signal Analysis

- Fixed-Point Implementation

- Code Refactoring

- Hardware-Oriented Optimization

---
## Current Implementation & Demo Simulation

1. **Signal Generator Object:** This module generates an instance of the analog input signal to be digitized, consisting of a sinusoidal baseband signal (core data), high-frequency interference signal, DC offset, and AWGN noise floor.

**Key Implementation Features:**

- **Non-Stationary Envelope Generation:** Rather than generating a static, continuous sine wave, the baseband signal is amplitude-modulated using a custom envelope i.e. a Gaussian pulse followed by an exponential fade.

- **Real-World Transient Simulation:** This envelope creates a dynamic "burst and decay" profile, simulating the transient nature of real-world physical sources (such as human speech). This non-stationary behavior provides the necessary amplitude variance to rigorously test the downstream Automatic Gain Control (AGC) and quantization stages.

2. **DC Removal (HPF) Object:** This module generates an instance of an N-order Butterworth High-Pass Filter (HPF) to eliminate unwanted DC offset from the incoming signal. In DSP, DC offsets are not universally detrimental; for example, unipolar quantizers rely on an injected DC offset to lift the analog signal entirely above zero. However, this simulation implements a bipolar midtread quantizer, which requires the signal to swing symmetrically across its zero-crossing. In this architecture, a residual DC offset restricts the dynamic range and severely degrades the quantizer's operational accuracy, making this HPF stage critical.
   
**Key Implementation Features:**

- **Numerically Robust ZPK Formulation:** To prevent numerical instability and floating-point roundoff errors common in high-order filter calculations, the coefficients are mathematically derived using a cascaded second-order section (SoS) Zero-Pole-Gain (ZPK) formulation.

3. **Anti-Aliasing Filter (LPF):** This module generates an instance of an N-order Butterworth Low-Pass Filter (LPF) to strictly band-limit the incoming analog signal before it reaches the sampler. According to the Nyquist-Shannon sampling theorem, a system must sample at a rate at least twice the highest frequency present in the signal to prevent distortion. If frequencies exceeding the Nyquist limit ($f_s / 2$) enter the sampler, they "fold" back into the baseband, masquerading as lower frequencies. This phenomenon, known as aliasing, introduces irreversible inharmonic distortion that cannot be mathematically removed post-conversion.

**Key Implementation Features:**

- **Numerically Robust ZPK Formulation:** Just like the DC removal stage, to prevent numerical instability and floating-point roundoff errors common in high-order filter calculations, the coefficients are mathematically derived using a cascaded second-order section (SoS) Zero-Pole-Gain (ZPK) formulation.

4. **Feedforward Time-Varying Automatic Gain Control (AGC) With Noise Gate:** This module generates an AGC instance to dynamically adjust the gain of the incoming analog signal over time. Its primary function is to maintain the signal's amplitude integrity, ensuring it consistently utilizes the full dynamic range of the subsequent bipolar midtread quantizer without clipping. To prevent the system from amplifying the noise floor during quiet periods (such as fading audio), the module integrates a Noise Gate. The noise gate dictates the AGC's behavior under low Signal-to-Noise Ratio (SNR) conditions:

- **Signal Detection:** When the target signal drops below a defined threshold and is barely present amidst the white noise, the gate activates.

- **Gain Suspension:** Suspends the AGC's gain updates to prevent unwanted amplification of the noise floor. By freezing the gain during quiet periods, the noise gate prevents noticeable "noise pumping" and preserves the signal's fidelity at the quantizer's output.

**Key Implementation Features:**

- **Peak Envelope Detector:** Chosen over RMS detection to ensure deterministic quantizer safety. By tracking the true peak rather than energy averages, the system reacts to sudden transients faster, preventing hard-clipping and maintaining high fidelity signal mapping within the quantizer’s full-scale range.
- **Dynamic Thresholding:** Rather than relying on a hardcoded static value, the noise gate threshold is dynamically calculated based on the system's simulated noise floor parameter. This tightly couples the AGC to the input stage, ensuring the gate remains accurate even if the noise variance changes.
- **Leaky Integrator Smoothing:** The AGC utilizes leaky integrators for envelope detection and gain application. This ensures smooth transitions during signal conditioning and prevents the abrupt, unnatural "clicking" artifacts that can occur when a noise gate opens or closes.
- **Dynamic Headroom Mapping:** The upper and lower gain limits are parameterized to 75% and 30% of the subsequent quantizer stage's peak voltage, respectively, ensuring improved gain scaling prior to quantization.
  
5. **ADC (Sampler + Quantizer):** This module combines a uniform sampler and a midtread bipolar quantizer to convert the continuous analog signal into a discrete digital output. The midtread architecture is prioritized over a midrise approach because it provides a true "zero" representation level. When the analog input is zero or contains negligible noise, the digital output remains exactly zero, effectively preventing idle channel noise and limit cycle oscillations.

**Key Implementation Features:**
- **Dynamic Parameterization:** Avoids hardcoded values by injecting key hardware specifications (Sampling frequency ($F_s$), full scale voltage ($V_{fs}$), downsampling factor ($DF$), and bit resolution ($B$)) upon instantiation. These parameters dynamically calculate the precise quantization step size ($\Delta = V_{fs} / 2^B$), ADC sampling frequency, and bipolar full-scale range.
- **Clip Protection:** Integrates strict saturation logic aligned with the full-scale voltage range. This accurately simulates real-world hardware overflow and underflow scenarios, preventing erroneous out-of-bounds indexing during extreme signal peaks.
- **Explicit Quantization Error Extraction:** Isolates the quantization noise alongside the digitized signal. This is critical for evaluating the system's noise floor and calculating the Signal-to-Quantization-Noise Ratio (SQNR).

---

## Simulation, Results, & Analysis
---

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
                 
---

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
