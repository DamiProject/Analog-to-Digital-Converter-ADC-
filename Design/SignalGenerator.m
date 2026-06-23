classdef SignalGenerator < handle
    %% ===================================
    %% Test Signal Generation For THE ADC 
    %% ===================================
    properties 
        Parameters
    end
    methods
        %% =====================================
        %% Signal Generator Instance Constructor 
        %% =====================================
        function obj = SignalGenerator(P)
            obj.Parameters = P;
        end

        function [Inp_Sig, t, Components] = GenNoisySignal(obj)
            %% ==================================
            %% Composite Analog Signal Generator
            %% ==================================          
            
            % Time vector Parameters

            Fs = obj.Parameters.getValue("Fs"); % Sampling Rate
            Dur = obj.Parameters.getValue("Dur"); % Signal Duration
            
            % Time Vector 
            t = (0:1/Fs:Dur-1/Fs)';

            % Parameters of the information carrying Envelope signal based
            % on gaussian pulses.
            Aburst = obj.Parameters.getValue("Aburst"); % Burst amplitude
            mu = obj.Parameters.getValue("mu");% Peak location of amplitude
            Sigma = obj.Parameters.getValue("Sigma"); % Burst width
            Ad  = obj.Parameters.getValue("Ad"); % Envelope amplitude 
            
            % Gaussian-Burst Pulse Envelope
            BurstEnvelope = Aburst * exp(-((t - mu).^2) / (2 * Sigma^2));
            Envelope = Ad + BurstEnvelope;

            %Exponential Decay Parameters
            Lambda = obj.Parameters.getValue("Lambda"); %Decay constant
            EST = obj.Parameters.getValue("EST"); % Fading start time
             
            % Apply exponential decay after EST
            fade_idx = t >= EST;
            if any(fade_idx)
                first_fade_idx = find(fade_idx, 1);
                start_val = Envelope(first_fade_idx);
                
            % Fading wave of the information carrying Envelope signal based
            % on the principle of exponential decaying constant.   
                FadeEnvelope = exp(-Lambda * (t(fade_idx) - EST));
                
                % Apply the fading envelope to the signal
                Envelope(fade_idx) = start_val * FadeEnvelope;
            end
            
            % Parameters of the amplitude-varying test signal
            FData = obj.Parameters.getValue("FData"); % Data frequency

            % Controlled amplitude-varying test signal
            DataSignal = sin(2*pi*FData*t).*Envelope;
            
            % Out-of-Band noise signal Parameters.
            An = obj.Parameters.getValue("An"); % Unwanted noise amplitude
            Fnoise = obj.Parameters.getValue("Fnoise"); % noise frequency
            
            % Out-of-Band noise signal 
            NoiseSignal = An * sin(2*pi*Fnoise*t);
            
            % AWGN Parameter
            Anf = obj.Parameters.getValue("Anf"); % Noise floor amplitude

            % AWGN generation 
            NoiseFloor = Anf * randn(size(t));

            % DC Parameter
            DC = obj.Parameters.getValue("DC"); % DC Voltage
            
            % Composite Signal consisting of a DC, data,
            % out-of-band/in-band signal has test input to ADC.
            Inp_Sig = DC + DataSignal + NoiseSignal + NoiseFloor;  

            % Store Internal Signal Components For Testing/Debugging
            Components.Envelope = Envelope;
            Components.DataSignal = DataSignal;
            Components.NoiseSignal = NoiseSignal;
            Components.NoiseFloor = NoiseFloor;
            Components.DC = DC;
        end
    end
end




