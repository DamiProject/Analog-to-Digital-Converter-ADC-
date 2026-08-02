# Analog-to-Digital Signal Converter (ADC)

[![ADC Unit Tests](https://github.com/DamiProject/Analog-to-Digital-Converter-ADC-/actions/workflows/ADC-tests.yml/badge.svg?branch=development-branch)](https://github.com/DamiProject/Analog-to-Digital-Converter-ADC-/actions/workflows/ADC-tests.yml)

**Status: Under Active Development**

## Overview

This project implements and validates an end-to-end Analog-to-Digital Converter (ADC) pipeline in MATLAB. The pipeline models front-end signal generation and conditioning, anti-alias filtering, automatic gain control, sampling, bipolar quantization, digital code generation, and conversion-performance analysis. It explores two main areas:

1. **Digital Signal Processing (DSP) Paradigms:** Signal generation, filtering, automatic gain control, sampling, quantization, fixed-point implementation, and spectral analysis.

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

 **1. Signal Generator Object:** This module generates an instance of the analog input signal to be digitized, consisting of a sinusoidal baseband signal (core data), high-frequency interference signal, DC offset, and AWGN noise floor.

**Key Implementation Features:**

- **Non-Stationary Envelope Generation:** Rather than generating a static, continuous sine wave, the baseband signal is amplitude-modulated using a custom envelope i.e. a Gaussian pulse followed by an exponential fade.

- **Real-World Transient Simulation:** This envelope creates a dynamic "burst and decay" profile, simulating the transient nature of real-world physical sources (such as human speech). This non-stationary behavior provides the necessary amplitude variance to rigorously test the downstream Automatic Gain Control (AGC) and quantization stages.

 **2. DC Removal (HPF) Object:** This module generates an instance of an N-order Butterworth High-Pass Filter (HPF) to eliminate unwanted DC offset from the incoming signal. In DSP, DC offsets are not universally detrimental; for example, unipolar quantizers rely on an injected DC offset to lift the analog signal entirely above zero. However, this simulation implements a bipolar midtread quantizer, which requires the signal to swing symmetrically across its zero-crossing. In this architecture, a residual DC offset restricts the dynamic range and severely degrades the quantizer's operational accuracy, making this HPF stage critical.
   
**Key Implementation Features:**

- **Numerically Robust ZPK Formulation:** To prevent numerical instability and floating-point roundoff errors common in high-order filter calculations, the coefficients are mathematically derived using a cascaded second-order section (SoS) Zero-Pole-Gain (ZPK) formulation.

**3. Anti-Aliasing Filter (LPF):** This module generates an instance of an N-order Butterworth Low-Pass Filter (LPF) to band-limit the incoming analog signal before it reaches the sampler. According to the Nyquist-Shannon sampling theorem, a system must sample at a rate at least twice the highest frequency present in the signal to prevent distortion. If frequencies exceeding the Nyquist limit ($f_s / 2$) enter the sampler, they "fold" back into the baseband, masquerading as lower frequencies. This phenomenon, known as aliasing, introduces irreversible inharmonic distortion that cannot be mathematically removed post-conversion.

**Key Implementation Features:**

- **Numerically Robust ZPK Formulation:** Just like the DC removal stage, to prevent numerical instability and floating-point roundoff errors common in high-order filter calculations, the coefficients are mathematically derived using a cascaded second-order section (SoS) Zero-Pole-Gain (ZPK) formulation.
- **Oversampling Operation:**  By operating at an oversampled rate relative to a target signal's bandwidth, the transition band leading up to the Nyquist limit ($f_s / 2$) is significantly widened. This eliminates the need for an aggressive, high-order "brick-wall" filter with a steep cutoff, reducing filter complexity, computational load, and in-band phase distortion while maintaining anti-aliasing protection.

**4. Feedforward Time-Varying Automatic Gain Control (AGC) With Noise Gate:** This module generates an AGC instance to dynamically adjust the gain of the incoming analog signal over time. Its primary function is to drive the conditioned waveform toward a defined operating region within the bipolar midtread quantizer’s full-scale range. This improves dynamic-range utilization while reducing the likelihood of quantizer clipping and saturation. To prevent the system from amplifying the noise floor during quiet periods (such as a fading audio message), the module integrates a Noise Gate. The noise gate dictates the AGC's behavior under low Signal-to-Noise Ratio (SNR) conditions:

- **Signal Detection:** When the target signal drops below a defined threshold and is barely present amidst the white noise, the gate activates.

- **Gain Suspension:** Suspends the AGC's gain updates to prevent unwanted amplification of the noise floor. By freezing the gain during quiet periods, the noise gate prevents noticeable "noise pumping" and preserves the signal's fidelity at the quantizer's output.

**Key Implementation Features:**

- **Smoothed Peak Envelope Detector:** The AGC uses an absolute-value envelope detector with independent leaky integrator attack and release smoothing. Compared with RMS-based level detection, this structure responds more directly to extreme amplitude transients and allows the gain controller to preserve quantizer headroom while avoiding abrupt gain changes.
- **Dynamic Thresholding:** Rather than using a hardcoded gate threshold, the model derives it from the configured AWGN standard deviation. This keeps the noise gate operating point consistent with the noise level selected for each simulation scenario.
- **Leaky Integrator Smoothing:** The AGC utilizes leaky integrators for envelope detection and gain application. This ensures smooth transitions during signal conditioning and prevents the abrupt, unnatural "clicking" artifacts that can occur when a noise gate opens or closes.
- **Dynamic Headroom Mapping:** The upper and lower gain limits are parameterized to 75% and 30% of the subsequent quantizer stage's peak voltage, respectively, ensuring improved gain scaling prior to quantization.
  
5. **ADC (Sampler + Quantizer):** This module combines a uniform sampler and a bipolar midtread quantizer to convert the continuous analog signal into a discrete digital output. The midtread architecture is prioritized over a midrise approach because it provides a true "zero" representation level. When the analog input is zero or contains negligible noise, the digital output remains exactly zero, effectively preventing idle channel noise and limit cycle oscillations.

**Key Implementation Features:**
- **Dynamic Parameterization:** Avoids hardcoded values by injecting key hardware specifications (Sampling frequency ($F_s$), full scale voltage ($V_{fs}$), downsampling factor ($DF$), and bit resolution ($B$)) upon instantiation. These parameters dynamically calculate the precise quantization step size ($\Delta = V_{fs} / 2^B$), ADC sampling frequency, and bipolar full-scale range.
- **Clip Protection:** Integrates strict saturation logic aligned with the full-scale voltage range. This accurately simulates real-world hardware overflow and underflow scenarios, preventing erroneous out-of-bounds indexing during extreme signal peaks.
- **Explicit Quantization Error Extraction:** Isolates the quantization noise alongside the digitized signal. This is critical for evaluating the system's noise floor and calculating the Signal-to-Quantization-Noise Ratio (SQNR).

---

## Simulation, Results, & Analysis

### Signal Generation

A generated composite analog signal consisting of a 500 Hz data signal, a 0 Hz DC offset, an 8 kHz interference signal, and AWGN is used as the input signal in this project. It is fed into the time-varying AGC to demonstrate signal conditioning operations, the high-pass and low-pass filters to demonstrate DC offset and interference attenuation, respectively, and the ADC to convert the 500 Hz baseband data signal into its digital equivalent. Figure 2 shows the time-domain waveform and frequency spectrum of this composite input signal.

<img width="600" height="510" alt="image" src="https://github.com/user-attachments/assets/13c68321-ac29-41e6-95e9-d8b7a06fcd31" />

Figure 2: Composite time-domain waveform and frequency spectrum of the simulated analog input signal.

### Signal Filtering Operations

A 4<sup>th</sup>-order Butterworth HPF and 6<sup>th</sup>-order Butterworth LPF were used to attenuate the 0 Hz DC offset and out-of-band 8 kHz interference, respectively. While these filters suppress out-of-band components to protect the 500 Hz baseband data signal from aliasing, in-band AWGN naturally passes through alongside the signal into the AGC and ADC stage. This filtering stage conditions the signal to utilize the bipolar quantizer's full-scale dynamic range effectively. Figure 3 shows the frequency spectrum of the signal following filtering, where the DC offset and 8 kHz interference have been attenuated.

<img width="600" height="510" alt="image" src="https://github.com/user-attachments/assets/fd541add-e1db-4970-a267-09956a49bdee" />

Figure 3: Step-by-step spectral transformation showing raw input (top), DC offset removal via HPF (middle), and high-frequency interference attenuation via LPF (bottom).

#### Benchmark

As shown in Figure 3, the HPF and LPF successfully attenuated the DC offset and 8 kHz interference signal. Because the primary objective at this stage is to demonstrate a functional filter model without formal system specifications, detailed performance trade-offs and analysis are omitted. Future iterations will evaluate filter characteristics, such as order selection, roll-off rate, frequency response, phase linearity, group delay, and stability, against defined system requirements to provide a comprehensive performance analysis.

### Signal Conditioning Operations

Unlike the filtering stage, signal conditioning for the 500 Hz baseband data signal was designed around these defined system specifications:

1. The time-varying AGC must suspend gain adjustment when the smoothed input envelope falls below the noise gate threshold derived from the configured AWGN standard deviation.
2. The time-varying AGC should preserve the non-stationary amplitude dynamics of the data signal rather than forcing it to a constant target level.
3. Signal amplitude must be scaled to stay within the quantizer's full-scale dynamic range to prevent clipping and saturation.

Because of these specifications, these design choices were made:

1. A noise gate freezes AGC gain updates when the smoothed input envelope falls below the configured threshold. Independent leaky integrator attack and release smoothing controls gate opening and closing, reducing abrupt transitions and limiting noise pumping during low-level signal intervals.
2. To preserve the non-stationary amplitude dynamics of the data signal, the AGC evaluates three distinct operational regions relative to the bipolar midtread quantizer's peak voltage:
   
   **a. Below 30% Peak:** The AGC applies leaky integrator gain boost to effectively utilize the quantizer's dynamic range.

   **b. Between 30% and 75% Peak:** The AGC maintains constant gain, allowing natural non-stationary amplitude variations to pass through untouched.

   **c. Above 75% Peak:** The AGC applies leaky integrator attenuation to bring the signal within peak limits and prevent quantizer saturation/clipping.

<img width="1000" height="600" alt="image" src="https://github.com/user-attachments/assets/2231baf0-b8d7-401f-885a-3dc56556fe6c" />

Figure 4: Dynamic signal conditioning showing envelope tracking, dual-limit AGC gain control, and noise gate attenuation under low signal-to-noise ratio conditions.

#### Benchmark

As shown in Figure 4, for the demonstrated signal and parameter configuration, zero out-of-range samples were observed. This result verifies that the AGC kept the conditioned waveform within the configured full-scale range throughout the simulation without causing quantizer saturation.

### ADC Sampling & Quantization Operation

Sampling and quantization of the 500 Hz baseband data signal was designed around these defined system specifications: 

1. **Nyquist Compliance (Anti-Aliasing):** The sampling rate ($F_s$) must strictly satisfy the Nyquist-Shannon sampling criterion ($F_s > 2 f_{\text{max}}$) to prevent undersampling and spectral aliasing of the 500 Hz baseband data signal.
2. **Quantizer Architecture:** The quantizer must incorporate an explicit zero-voltage representation level ($0\text{ V}$) to accurately represent zero-signal and silent states without introducing a DC bias and can handle positive and negative voltage levels.
3. **Full-Scale Dynamic Range Bounding:** The quantizer must enforce hard saturation limits at full scale ($\pm V_{\text{fs}}/2$) to clamp extreme signal peak and protect the digital output from unexpected arithmetic overflow.
4. **Zero Dynamic Overflow:** Under nominal AGC-conditioned inputs, zero out-of-range samples must occur during quantization.

Because of these specifications, these design choices were made:

1. **Sampling Rate Selection:** A sampling rate of $F_s = 5\text{ kHz}$ was implemented, providing a $5\times$ oversampling factor above the $1\text{ kHz}$ Nyquist rate for the $500\text{ Hz}$ baseband signal.
2. **Bipolar Midtread Quantizer:** An 8-bit uniform midtread quantizer architecture was selected to guarantee an exact digital $0\text{ V}$ code and provide balanced quantization across positive and negative input swings.
3. **AGC Peak Scaling & Dynamic Clamping:** Front-end AGC dynamic headroom scaling combined with explicit hard-saturation logic ($\pm V_{\text{fs}}/2$) in the quantizer prevents dynamic range overflow and ensures zero out-of-range samples.

 <img width="1000" height="600" alt="image" src="https://github.com/user-attachments/assets/6965de98-b083-4d24-82db-ada7343a8a38" />

 Figure 5: Time-domain waveform and spectral analysis of signal sampling, midtread quantization, and quantization error.

 <img width="1000" height="600" alt="image" src="https://github.com/user-attachments/assets/ab2aaf79-1291-4e46-816e-0215d5e1cfdf" />

 Figure 6: Frequency spectrum comparison of the 500 Hz baseband signal before and after 8-bit midtread quantization.

<img width="482" height="284" alt="image" src="https://github.com/user-attachments/assets/39b519d5-093e-4976-8850-db3a7e308124" />

Figure 7: Simulation execution summary detailing key ADC system parameters and quantitative performance metrics.
  
#### Benchmark

As demonstrated in Figures 5 and 6, the 8-bit bipolar midtread quantizer preserves the spectral integrity of the 500 Hz baseband data signal while maintaining quantization error strictly within theoretical bounds. 

Figure 7 confirms high-fidelity conversion performance, achieving an empirical SQNR of 43.52 dB and zero out-of-range samples, validating that the dynamic AGC range and 5 kHz sampling rate effectively eliminate quantization saturation. Future iterations will evaluate performance trade-offs across sampling rate selection, bit depth, SQNR, and quantization error.

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
