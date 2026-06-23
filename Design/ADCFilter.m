classdef ADCFilter < handle
    %% ====================================================
    %% PERFORMS HPF, ANTI-ALIASING/LPF FILTERING OPERATIONS
    %% ====================================================

    properties
        Parameters
    end

    methods
        function obj = ADCFilter(P)
            %% HPF OR LPF INSTANCE CONSTRUCTOR
            obj.Parameters = P;
        end

        function [b_hpf,a_hpf] = DCRemoval(obj)

            %% Performs DC offset Removal using High-Pass Filter.
            FcHigh = obj.Parameters.getValue("FcHigh"); %Cutoff Frequency
            Fs = obj.Parameters.getValue("Fs");% Sampling Rate
            nHpf = obj.Parameters.getValue("nHpf"); % Filter Order
             
            % Butterworth filter design in Zero-Pole-Gain (ZPK) form.
            [z_hp, p_hp, k_hp] = butter(nHpf, (2*FcHigh)/Fs,"high");

            % Convert ZPK to transfer function polynomial coefficients
            % b_hpf: Numerator (Feedforward coefficients applied to input)
            % a_hpf: Denominator (Feedback coefficients applied to output)
            [b_hpf,a_hpf] = zp2tf(z_hp, p_hp, k_hp);
        end

        function [b_lpf,a_lpf] = AAF(obj)

            %% Performs high frequency noise and aliasing removal.
            FcLow = obj.Parameters.getValue("FcLow"); % Cutoff Frequency
            Fs = obj.Parameters.getValue("Fs");% Sampling Rate
            nLpf = obj.Parameters.getValue("nLpf"); % Filter Order

            % Butterworth filter design in Zero-Pole-Gain (ZPK) form.
            [z_lp, p_lp, k_lp] = butter(nLpf, (2*FcLow)/Fs,"low");

            % Convert ZPK to transfer function polynomial coefficients
            % b_lpf: Numerator (Feedforward coefficients applied to input)
            % a_lpf: Denominator (Feedback coefficients applied to output)
            [b_lpf,a_lpf] = zp2tf(z_lp, p_lp, k_lp);
        end
    end
end