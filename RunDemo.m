%% ============================================================
%% ADC DEMO SCRIPT Demonstrates Signal Generator, HPF, LPF/AAF, 
%% AGC, and Noise Gate
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
P.setValue("Vfs", 1.0);            % Quantizer full-scale reference
P.setValue("EnvAttack", 0.002);    % Envelope detector attack
P.setValue("EnvRelease", 0.020);   % Envelope detector release
P.setValue("GainAttack", 0.0015);   % AGC gain attack
P.setValue("GainRelease", 0.030);  % AGC gain release
P.setValue("GateAttack", 0.007);   % Noise gate opening time
P.setValue("GateRelease", 0.020);  % Noise gate closing time

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
grid on;
title("FFT of Generated ADC Input: DC + Data + HF Interference + AWGN");
xlabel("Frequency (Hz)");
ylabel("Magnitude");
ylim([0 0.5]);
xlim([0 Fs/2 + 1000]);

%% =========================
%% 3. HPF + LPF / AAF DEMO
%% ==========================

F = ADCFilter(P);

[b_hpf, a_hpf] = F.DCRemoval();
x_hpf = filter(b_hpf, a_hpf, Inp_Sig);

[b_lpf, a_lpf] = F.AAF();
x_lpf = filter(b_lpf, a_lpf, x_hpf);

[f_raw, X_raw] = singleSidedFFT(Inp_Sig, Fs);
[f_hpf, X_hpf] = singleSidedFFT(x_hpf, Fs);
[f_lpf, X_lpf] = singleSidedFFT(x_lpf, Fs);

figure("Name", "FFT Input Signal Before and After HPF / LPF");
tiledlayout(3,1);

nexttile;
plot(f_raw, X_raw);
title("Frequency Domain Input Signal");
xlabel("Frequency (Hz)");
ylabel("Magnitude");
legend("Raw Input");
ylim([0 0.5]);
xlim([0 Fs/2 + 1000]);
grid on;

nexttile;
plot(f_hpf, X_hpf);
title("Input signal after DC offset removal");
xlabel("Frequency (Hz)");
ylabel("Magnitude");
legend("After HPF");
ylim([0 0.5]);
xlim([0 Fs/2 + 1000]);
grid on;

nexttile;
plot(f_lpf, X_lpf);
title("Input signal after aliasing removal");
xlabel("Frequency (Hz)");
ylabel("Magnitude");
legend("After HPF + LPF");
ylim([0 0.5]);
xlim([0 Fs/2 + 1000]);
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
yline(0.75 * P.getValue("Vfs"), "--", "Upper AGC Limit");
yline(0.30 * P.getValue("Vfs"), "--", "Lower AGC Limit");
grid on;
title("Envelope Tracking and Projected Output Envelope");
xlabel("Time (s)");
ylabel("Envelope");

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