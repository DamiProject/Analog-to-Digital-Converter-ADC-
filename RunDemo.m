%% ============================================================
%% ADC DEMO SCRIPT Demonstrates Signal Generator, HPF, LPF/AAF,
%% AGC, Noise Gate, Sampling, and Quantization
%% ============================================================

clc;
clear;
close all;

%% Project Paths
projectRoot = fileparts(mfilename("fullpath"));
addpath(fullfile(projectRoot, "Design"));

%% Reproducibility
rng(7, "twister");

%% ============================================================
%% 1. DEFINE ADC PARAMETERS
%% ============================================================

P = Parameters();

% Sampling / signal generation
P.setValue("Fs", 20000);       % Oversampling frequency, Hz
P.setValue("Dur", 0.20);       % Signal duration, seconds
P.setValue("FData", 500);      % Desired data signal frequency, Hz

% ADC sampling / quantization
P.setValue("DF", 4);            % Downsampling factor
P.setValue("NumBits", 8);       % ADC resolution, bits

% Time-varying envelope
P.setValue("Ad", 0.25);        % Base signal amplitude
P.setValue("Aburst", 0.75);    % Gaussian burst amplitude
P.setValue("mu", 0.06);        % Burst peak location, seconds
P.setValue("Sigma", 0.015);    % Burst width
P.setValue("Lambda", 18);      % Exponential decay constant
P.setValue("EST", 0.11);       % Exponential decay start time, seconds

% Unwanted components
P.setValue("DC", 0.25);        % DC offset to be removed by HPF
P.setValue("An", 0.15);        % High-frequency interference amplitude
P.setValue("Fnoise", 8000);    % High-frequency interference, Hz
P.setValue("Anf", 0.1);       % AWGN noise floor amplitude

% Filter design
P.setValue("FcHigh", 20);      % HPF cutoff for DC removal, Hz
P.setValue("FcLow", 2200);     % LPF/AAF cutoff, Hz
P.setValue("nHpf", 4);         % HPF order
P.setValue("nLpf", 6);         % LPF order

% AGC / noise gate
P.setValue("Vfs", 1.0);            % Quantizer full-scale Range
P.setValue("EnvAttack", 0.0006);    % Envelope detector attack
P.setValue("EnvRelease", 0.020);   % Envelope detector release
P.setValue("GainAttack", 0.0006);   % AGC gain attack
P.setValue("GainRelease", 0.030);  % AGC gain release
P.setValue("GateAttack", 0.007);   % Noise gate opening time
P.setValue("GateRelease", 0.020);  % Noise gate closing time

Vfs = P.getValue("Vfs"); % Quantizer full-scale Range
QuantizerPeak = Vfs / 2; % Quantizer Peak Voltage 
SquaredSymbol = char(178);

%% ==========================
%% 2. SIGNAL GENERATOR DEMO
%% ===========================

SG = SignalGenerator(P);
[Inp_Sig, t, Components] = SG.GenNoisySignal();

Fs = P.getValue("Fs");

[f_Inp, X_Inp]       = singleSidedFFT(Inp_Sig, Fs);
[f_Data, X_Data]     = singleSidedFFT(Components.DataSignal, Fs);
[f_Noise, X_Noise]   = singleSidedFFT(Components.NoiseSignal, Fs);

figure("Name", "Signal Generator Demo");
tiledlayout(2,1);

nexttile;
plot(t, Inp_Sig);
grid on;
title("Generated ADC Input: DC + Data + HF Interference + AWGN");
xlabel("Time (s)");
ylabel("Amplitude");

nexttile;
plot(f_Inp, X_Inp);
hold on;
% Locate the frequency bin closest to 0 Hz
[~, DCBin] = min(abs(f_Inp));

plot([0 0], [0 X_Inp(DCBin)], ...
    "r-", ...
    "LineWidth", 2, ...
    "HandleVisibility", "off");

scatter(f_Inp(DCBin), X_Inp(DCBin), ...
    55, "red", "filled", ...
    "MarkerEdgeColor", "black", ...
    "LineWidth", 0.8, ...
    "HandleVisibility", "off");

text(70, X_Inp(DCBin), "DC", ...
    "VerticalAlignment", "middle", ...
    "HorizontalAlignment", "left");
grid on;
title("FFT of Generated ADC Input: DC + Data + HF Interference + AWGN");
xlabel("Frequency (Hz)");
ylabel("Magnitude");
ylim([0 0.5]);
xlim([-100 Fs/2]);
xticks(0:500:Fs/2);

%% =========================
%% 3. HPF + LPF / AAF DEMO
%% ==========================

F = ADCFilter(P);

[sos_hpf, g_hpf] = F.DCRemoval();
x_hpf = g_hpf * sosfilt(sos_hpf, Inp_Sig);

[sos_lpf, g_lpf] = F.AAF();
x_lpf = g_lpf * sosfilt(sos_lpf, x_hpf);

[f_raw, X_raw] = singleSidedFFT(Inp_Sig, Fs);
[f_hpf, X_hpf] = singleSidedFFT(x_hpf, Fs);
[f_lpf, X_lpf] = singleSidedFFT(x_lpf, Fs);

figure("Name", "FFT Input Signal Before and After HPF / LPF");
tiledlayout(3,1);

nexttile;
plot(f_raw, X_raw);
hold on;
% Locate the frequency bin closest to 0 Hz
[~, DCBin] = min(abs(f_raw));

plot([0 0], [0 X_raw(DCBin)], ...
    "r-", ...
    "LineWidth", 2, ...
    "HandleVisibility", "off");

scatter(f_raw(DCBin), X_raw(DCBin), ...
    55, "red", "filled", ...
    "MarkerEdgeColor", "black", ...
    "LineWidth", 0.8, ...
    "HandleVisibility", "off");

text(70, X_raw(DCBin), "DC", ...
    "VerticalAlignment", "middle", ...
    "HorizontalAlignment", "left");
title("Generated Input Signal Spectrum");
xlabel("Frequency (Hz)");
ylabel("Magnitude");
legend("Raw Input");
ylim([0 0.5]);
xlim([-100 Fs/2]);
xticks(0:500:Fs/2);
grid on;

nexttile;
plot(f_hpf, X_hpf);
title("Spectrum After DC-Offset Removal");
xlabel("Frequency (Hz)");
ylabel("Magnitude");
legend("After HPF");
ylim([0 0.5]);
xlim([-100 Fs/2]);
xticks(0:500:Fs/2);
grid on;

nexttile;
plot(f_lpf, X_lpf);
title("Spectrum After DC Removal and Anti-Alias Filtering");
xlabel("Frequency (Hz)");
ylabel("Magnitude");
legend("After HPF + LPF");
ylim([0 0.5]);
xlim([-100 Fs/2]);
xticks(0:500:Fs/2);
grid on;

%% ============================================================
%% 4. AGC ON FILTERED SIGNAL
%% ============================================================

A = AGC(P);
[y_frontend, t_agc, History] = A.GainControl(x_lpf);

figure("Name", "AGC Applied To Filtered Signal");
tiledlayout(4,1);

nexttile;
plot(t_agc, x_lpf);
hold on;
plot(t_agc, y_frontend);
grid on;
title("Filtered Signal Before and After AGC + Noise Gate");
xlabel("Time (s)");
ylabel("Amplitude");
legend("Filtered Input", "AGC + Gate Output");

nexttile;
plot(t_agc, History.Envelope);
hold on;
plot(t_agc, History.ProjectedEnvelope);
yline(0.75 * QuantizerPeak, "--", "Upper AGC Limit");
yline(0.30 * QuantizerPeak, "--", "Lower AGC Limit");
grid on;
title("Envelope Tracking and Projected Output Envelope");
xlabel("Time (s)");
ylabel("Envelope");
legend("Filtered Input", "AGC + Gate Output");
nexttile;
plot(t_agc, History.Gain);
grid on;
title("AGC Gain History");
xlabel("Time (s)");
ylabel("Gain");

nexttile;
plot(t_agc, History.GateGain);
grid on;
title("Noise Gate Gain History");
xlabel("Time (s)");
ylabel("Gate Gain");

%% ============================================================
%% 5. ADC SAMPLING AND QUANTIZATION
%% ============================================================

Converter = ADC(P);

% Sample the conditioned analogue-front-end output at Fs/DF.
[DiscreteSignal, SampleIndex, ADCSamplingFrequency] = ...
    Converter.Sampler(y_frontend);

% Demonstrate uniform bipolar quantizers implemented by ADC.
[MidtreadSignal, MidtreadIndices, MidtreadError] = ...
    Converter.Midtread(DiscreteSignal);

DF = P.getValue("DF");
NumBits = P.getValue("NumBits");
Delta = Vfs / 2^NumBits;

% Sampler returns indices into the original oversampled input.
t_frontend = t_agc(:);
y_frontend = y_frontend(:);
t_adc = t_frontend(SampleIndex);

% Use a short time window so the individual ADC samples and levels are clear.
DisplayDuration = min(0.2, t_adc(end));
FrontendDisplay = t_frontend <= DisplayDuration;
ADCDisplay = t_adc <= DisplayDuration;

figure("Name", "ADC Sampling and Quantization Demo");
tiledlayout(2,2);

nexttile;
plot(t_frontend(FrontendDisplay), y_frontend(FrontendDisplay));
hold on;
stem(t_adc(ADCDisplay), DiscreteSignal(ADCDisplay), "filled", ...
    "MarkerSize", 3);
yline(QuantizerPeak, "--", "+V_{FS}/2", ...
    "HandleVisibility", "off");
yline(-QuantizerPeak, "--", "-V_{FS}/2", ...
    "HandleVisibility", "off");
grid on;
title(sprintf( ...
    "Conditioned ADC Input and Sampling: F_s = %.0f Hz, F_{ADC} = %.0f Hz", ...
    Fs, ADCSamplingFrequency));
xlabel("Time (s)");
ylabel("Amplitude (V)");
legend("AGC + Gate Output", "ADC Samples", "Location", "best");
ylim([-0.7 0.7]);
xlim([0 0.2]);

nexttile;
stairs(t_adc(ADCDisplay), DiscreteSignal(ADCDisplay));
hold on;
stairs(t_adc(ADCDisplay), MidtreadSignal(ADCDisplay));
yline(QuantizerPeak, "--", "+V_{FS}/2", ...
    "HandleVisibility", "off");
yline(-QuantizerPeak, "--", "-V_{FS}/2", ...
    "HandleVisibility", "off");
grid on;
title(sprintf("%d-bit Bipolar Quantization, Step Size = %.6f V", ...
    NumBits, Delta));
xlabel("Time (s)");
ylabel("Amplitude (V)");
legend("Sampled Input", "Midtread", "Location", "best");
ylim([-0.7 0.7]);
xlim([0 0.2]);

nexttile;
plot(t_adc(ADCDisplay), MidtreadError(ADCDisplay));
yline(Delta/2, "--", "+\Delta/2", ...
    "HandleVisibility", "off");
yline(-Delta/2, "--", "-\Delta/2", ...
    "HandleVisibility", "off");
grid on;
title("Quantization Error");
xlabel("Time (s)");
ylabel("Error (V)");
ErrorLimit = 1.25 * (Delta / 2);
ylim([-ErrorLimit ErrorLimit]);
yticks([-Delta/2, 0, Delta/2])
xlim([0 0.2]);

nexttile;
stairs(t_adc(ADCDisplay), MidtreadIndices(ADCDisplay));
grid on;
title("Unsigned ADC Output Code Indices");
xlabel("Time (s)");
ylabel("Code");
MaxCode = 2^NumBits - 1;
TickStep = 2^(NumBits - 2);
TickValues = [0:TickStep:(2^NumBits - TickStep), MaxCode];
ylim([0 MaxCode]);
yticks(TickValues);
yline((2^NumBits)/2, "--", "Zero-Volt Code");
legend("Midtread Codes", "Location", "best");

% Compare the sampled and quantized spectra at the actual ADC rate.
[f_sampled, X_sampled] = ...
    singleSidedFFT(DiscreteSignal, ADCSamplingFrequency);
[f_midtread, X_midtread] = ...
    singleSidedFFT(MidtreadSignal, ADCSamplingFrequency);

figure("Name", "ADC Output Spectrum");
plot(f_sampled, X_sampled);
hold on;
plot(f_midtread, X_midtread);

MaxMagnitude = max([X_sampled; X_midtread]);

xlim([0 ADCSamplingFrequency/2]);
ylim([0 1.10 * MaxMagnitude]);

FData = P.getValue("FData");

[~, DataBin] = min(abs(f_sampled - FData));
DataMagnitude = max(X_sampled(DataBin), X_midtread(DataBin));

plot([FData FData], [0 DataMagnitude], "k--");

ax = gca;
xOffset = 0.005 * diff(ax.XLim);
yOffset = 0.015 * diff(ax.YLim);

text(FData + xOffset, DataMagnitude + yOffset, ...
    "Data Frequency", ...
    "HorizontalAlignment", "left", ...
    "VerticalAlignment", "bottom");

grid on;
title("Spectrum Before and After Quantization");
xlabel("Frequency (Hz)");
ylabel("Magnitude");
legend("Sampled Input", "Midtread Output");

% Basic numerical checks reported in the Command Window.
OutOfRangeSamples = nnz(DiscreteSignal < -QuantizerPeak | ...
    DiscreteSignal > QuantizerPeak);
MidtreadRMSError = sqrt(mean(MidtreadError.^2));

Signal =  mean(DiscreteSignal.^2);
Noise  =  (mean(MidtreadError.^2));
SQNR_dB     = 10 * log10 (Signal / Noise);

Correlation = corrcoef(DiscreteSignal, MidtreadSignal);
CorrelationCoefficient = Correlation(1,2);

fprintf("\n========== ADC DEMO SUMMARY ==========\n");
fprintf("Oversampling frequency:          %.0f Hz\n", Fs);
fprintf("Downsampling factor:             %d\n", DF);
fprintf("ADC sampling frequency:          %.0f Hz\n", ...
    ADCSamplingFrequency);
fprintf("ADC Nyquist frequency:           %.0f Hz\n", ...
    ADCSamplingFrequency/2);
fprintf("ADC resolution:                  %d bits (%d codes)\n", ...
    NumBits, 2^NumBits);
fprintf("Quantization step size:          %.6f V\n", Delta);
fprintf("Oversampled / ADC sample count:  %d / %d\n", ...
    numel(y_frontend), numel(DiscreteSignal));
fprintf("Out-of-range input samples:      %d\n", OutOfRangeSamples);
fprintf("RMS Quantization error:          %.6e V\n", ...
    MidtreadRMSError);
fprintf("Mean- Square Signal voltage :    %.6e V%s\n", ...
    Signal, SquaredSymbol);
fprintf("Quantization Noise :              %.6e V%s\n", ...
    Noise, SquaredSymbol);
fprintf("SQNR:                            %.2f dB\n", ...
    SQNR_dB);
fprintf("Correlation Coefficient:         %.6f\n", ...
    CorrelationCoefficient);
fprintf("======================================\n");

%% ======================
%% LOCAL HELPER FUNCTION
%% ======================

function [f, Xmag] = singleSidedFFT(x, Fs)
x = x(:);
N = numel(x);

X = fft(x);
Xmag = abs(X/N);

Xmag = Xmag(1:floor(N/2)+1);
Xmag(2:end-1) = 2*Xmag(2:end-1);

f = Fs*(0:floor(N/2))'/N;
end