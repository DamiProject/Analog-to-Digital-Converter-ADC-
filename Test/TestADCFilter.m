classdef TestADCFilter < matlab.unittest.TestCase
    %% =================================
    %% UNIT TEST SUITE FOR FILTER CLASS
    %% =================================

    methods (Test)

        function testConstructorStoresParametersObject(testCase)
            %% Validates Constructor Stores Parameters Handle

            P = testCase.createDefaultParameters();
            F = ADCFilter(P);

            testCase.verifySameHandle(F.Parameters, P);
        end

        function testDCRemovalReturnsValidSOS(testCase)
            %% Validates HPF Returns a Valid SOS Matrix and Scalar Gain

            P = testCase.createDefaultParameters();
            F = ADCFilter(P);

            nHpf = P.getValue("nHpf");
            [sos, g] = F.DCRemoval();

            testCase.verifyValidSOS(sos, g, nHpf);
        end

        function testAAFReturnsValidSOS(testCase)
            %% Validates LPF Returns a Valid SOS Matrix and Scalar Gain

            P = testCase.createDefaultParameters();
            F = ADCFilter(P);

            nLpf = P.getValue("nLpf");
            [sos, g] = F.AAF();

            testCase.verifyValidSOS(sos, g, nLpf);
        end

        function testDCRemovalMatchesExpectedHighPassButterworth(testCase)
            %% Validates DCRemoval Designs the Expected Butterworth HPF

            P = testCase.createDefaultParameters();
            F = ADCFilter(P);

            FcHigh = P.getValue("FcHigh"); % Cutoff Frequency
            Fs     = P.getValue("Fs");     % Sampling Frequency
            nHpf   = P.getValue("nHpf");   % Filter Order

            [sosActual, gActual] = F.DCRemoval();

            [zExpected, pExpected, kExpected] = ...
                butter(nHpf, (2 * FcHigh) / Fs, "high");
            [sosExpected, gExpected] = ...
                zp2sos(zExpected, pExpected, kExpected);

            testCase.verifyEqual( ...
                sosActual, sosExpected, "AbsTol", 1e-12);
            testCase.verifyEqual( ...
                gActual, gExpected, "AbsTol", 1e-12);
        end

        function testAAFMatchesExpectedLowPassButterworth(testCase)
            %% Validates AAF Designs the Expected Butterworth LPF

            P = testCase.createDefaultParameters();
            F = ADCFilter(P);

            FcLow = P.getValue("FcLow"); % Cutoff Frequency
            Fs    = P.getValue("Fs");    % Sampling Frequency
            nLpf  = P.getValue("nLpf");  % Filter Order

            [sosActual, gActual] = F.AAF();

            [zExpected, pExpected, kExpected] = ...
                butter(nLpf, (2 * FcLow) / Fs, "low");
            [sosExpected, gExpected] = ...
                zp2sos(zExpected, pExpected, kExpected);

            testCase.verifyEqual( ...
                sosActual, sosExpected, "AbsTol", 1e-12);
            testCase.verifyEqual( ...
                gActual, gExpected, "AbsTol", 1e-12);
        end

        function testDCRemovalBehavesAsHighPass(testCase)
            %% Validates HPF Rejects DC and Passes High Frequency

            P = testCase.createDefaultParameters();
            F = ADCFilter(P);

            [sos, g] = F.DCRemoval();

            % Evaluate the complete SOS cascade, including overall gain,
            % at DC and the Nyquist frequency.
            H = g .* freqz(sos, [0, pi]);

            Hdc   = H(1);
            Hhigh = H(2);

            testCase.verifyLessThan(abs(Hdc), 1e-6);
            testCase.verifyGreaterThan(abs(Hhigh), 0.7);
        end

        function testAAFBehavesAsLowPass(testCase)
            %% Validates AAF Passes DC and Rejects High Frequency

            P = testCase.createDefaultParameters();
            F = ADCFilter(P);

            [sos, g] = F.AAF();

            % Evaluate the complete SOS cascade, including overall gain,
            % at DC and the Nyquist frequency.
            H = g .* freqz(sos, [0, pi]);

            Hdc   = H(1);
            Hhigh = H(2);

            testCase.verifyGreaterThan(abs(Hdc), 0.7);
            testCase.verifyLessThan(abs(Hhigh), 1e-3);
        end

        function testDCRemovalHasButterworthCutoffResponse(testCase)
            %% Validates HPF Magnitude Is Approximately -3 dB at Cutoff

            P = testCase.createDefaultParameters();
            F = ADCFilter(P);

            FcHigh = P.getValue("FcHigh");
            Fs     = P.getValue("Fs");

            [sos, g] = F.DCRemoval();

            cutoffFrequency = 2 * pi * FcHigh / Fs;
            Hcutoff = g .* freqz(sos, [cutoffFrequency, pi]);

            testCase.verifyEqual( ...
                abs(Hcutoff(1)), 1 / sqrt(2), "AbsTol", 1e-6);
        end

        function testAAFHasButterworthCutoffResponse(testCase)
            %% Validates LPF Magnitude Is Approximately -3 dB at Cutoff

            P = testCase.createDefaultParameters();
            F = ADCFilter(P);

            FcLow = P.getValue("FcLow");
            Fs    = P.getValue("Fs");

            [sos, g] = F.AAF();

            cutoffFrequency = 2 * pi * FcLow / Fs;
            Hcutoff = g .* freqz(sos, [cutoffFrequency, pi]);

            testCase.verifyEqual( ...
                abs(Hcutoff(1)), 1 / sqrt(2), "AbsTol", 1e-6);
        end

        function testDCRemovalFilterIsStable(testCase)
            %% Validates All HPF Poles Are Inside the Unit Circle

            P = testCase.createDefaultParameters();
            F = ADCFilter(P);

            [sos, g] = F.DCRemoval();
            [~, poles, ~] = sos2zp(sos, g);

            testCase.verifyLessThan(abs(poles), ones(size(poles)));
        end

        function testAAFFilterIsStable(testCase)
            %% Validates All LPF Poles Are Inside the Unit Circle

            P = testCase.createDefaultParameters();
            F = ADCFilter(P);

            [sos, g] = F.AAF();
            [~, poles, ~] = sos2zp(sos, g);

            testCase.verifyLessThan(abs(poles), ones(size(poles)));
        end
    end

    methods (Access = private)

        function verifyValidSOS(testCase, sos, g, filterOrder)
            %% Validates the Structure and Numeric Integrity of SOS Outputs

            expectedSections = ceil(filterOrder / 2);

            testCase.verifySize(sos, [expectedSections, 6]);
            testCase.verifyEqual( ...
                sos(:, 4), ones(expectedSections, 1), ...
                "AbsTol", 1e-12);

            testCase.verifyNotEmpty(sos);
            testCase.verifyTrue(isreal(sos));
            testCase.verifyTrue(all(isfinite(sos(:))));

            testCase.verifySize(g, [1, 1]);
            testCase.verifyTrue(isnumeric(g));
            testCase.verifyTrue(isreal(g));
            testCase.verifyTrue(isfinite(g));
        end

        function P = createDefaultParameters(~)
            %% Creates Default Parameter Object for Filter Tests

            P = Parameters();

            P.setValue("Fs", 20000);     % Sampling Frequency
            P.setValue("FcHigh", 20);    % HPF Cutoff Frequency
            P.setValue("FcLow", 5000);   % LPF Cutoff Frequency
            P.setValue("nHpf", 4);       % HPF Filter Order
            P.setValue("nLpf", 6);       % LPF Filter Order
        end
    end
end
