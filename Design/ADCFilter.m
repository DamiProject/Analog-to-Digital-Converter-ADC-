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

        function [sos_hpf, g_hpf] = DCRemoval(obj)

            %% Performs DC offset Removal using High-Pass Filter.
            FcHigh = obj.Parameters.getValue("FcHigh"); %Cutoff Frequency
            Fs = obj.Parameters.getValue("Fs");% Sampling Rate
            nHpf = obj.Parameters.getValue("nHpf"); % Filter Order
             
            % Butterworth filter design in Zero-Pole-Gain (ZPK) form.
            [z_hp, p_hp, k_hp] = butter(nHpf, (2*FcHigh)/Fs,"high");

            % Convert ZPK representation to second-order sections.
            % sos_hpf: Biquad section
            % g_hpf: Overall scalar filter gain
            [sos_hpf,g_hpf] = zp2sos(z_hp, p_hp, k_hp);
        end

        function [sos_lpf, g_lpf] = AAF(obj)

            %% Performs high frequency noise and aliasing removal.
            FcLow = obj.Parameters.getValue("FcLow"); % Cutoff Frequency
            Fs = obj.Parameters.getValue("Fs");% Sampling Rate
            nLpf = obj.Parameters.getValue("nLpf"); % Filter Order

            % Butterworth filter design in Zero-Pole-Gain (ZPK) form.
            [z_lp, p_lp, k_lp] = butter(nLpf, (2*FcLow)/Fs,"low");

            % Convert ZPK representation to second-order sections.
            % sos_lpf: Biquad section
            % g_lpf: Overall scalar filter gain
            [sos_lpf, g_lpf] = zp2sos(z_lp, p_lp, k_lp);
        end
    end
end
