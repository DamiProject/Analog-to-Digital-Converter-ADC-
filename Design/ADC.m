classdef ADC < handle
    %% ==============================
    %% SAMPLER AND QUANTIZER SYSTEM
    %% ==============================

    properties
        Parameters
    end

    methods
        function obj = ADC(P)
            %% ===========================================
            %% SAMPLER AND QUANTIZER INSTANCE CONSTRUCTOR
            %% ===========================================
            obj.Parameters = P;
        end

        function [DiscreteSignal, SampleIndex , ADCSamplingFrequency] = ...
            Sampler(obj,Input)
            %% ADC SAMPLING 

            %%DF = obj.Parameters.getValue("DF"); % Downsampling Factor
            Fs = obj.Parameters.getValue("Fs"); % Oversampling Frequency 

            Input = Input(:); %Input Signal Into The ADC 
            
            % Number of input samples
            N = numel(Input);
            
            % Operating Sampling Frequency of the ADC
            ADCSamplingFrequency = Fs; 
            % Sample Index of a Discrete Signal 
            SampleIndex = (1:N)';
            % Generate Discrete-Time Signal After ADC Sampling
            DiscreteSignal = Input(SampleIndex);
        end

        function [QuantSignal, Indices, Error] = Midtread(obj,Input)

            %% ADC Midtread Uniform Bipolar Quantizer

            Vfs = obj.Parameters.getValue("Vfs");% full-scale range
            NumBits = obj.Parameters.getValue("NumBits"); % Number of Bits

            Input = Input(:); %Discrete-time input signal

            Delta = Vfs/2^NumBits; % Quantization resolution

            min_Vfs = -(Vfs/2); % Lowest Quantizer voltage level

            Indices = round((Input-min_Vfs)/Delta); % Quantization Indices
            Indices = max(0, min(Indices, (2^NumBits- 1))); % Clip Protect

            QuantSignal = min_Vfs + (Indices * Delta); % Quantized Signal

            Error = QuantSignal - Input; % Quantization error
        end
    
        function [QuantSignal, Indices, Error] = Midrise(obj,Input)

            %% ADC Midrise Uniform Bipolar Quantizer

            Vfs = obj.Parameters.getValue("Vfs");% full-scale range
            NumBits = obj.Parameters.getValue("NumBits"); % Number of Bits

            Input = Input(:); %Discrete-time input signal

            Delta = Vfs/2^NumBits; % Quantization resolution

            min_Vfs = -(Vfs/2); % Lowest Quantizer voltage level

            Indices = floor((Input-min_Vfs)/Delta); % Quantization Indices

            Indices = max(0, min(Indices, (2^NumBits) - 1)); % Clip protect

            QuantSignal = min_Vfs + ...
            ((Indices + 0.5) * Delta); % Quantized Signal

            Error = QuantSignal - Input; % Quantization error
        end
    end
end