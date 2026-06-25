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


        function testDCRemovalReturnsValidCoefficients(testCase)
            %% Validates HPF Coefficients Are Real, Finite, and Nonempty

            P = testCase.createDefaultParameters();
            F = ADCFilter(P);

            [b, a] = F.DCRemoval();

            testCase.verifyNotEmpty(b);
            testCase.verifyNotEmpty(a);

            testCase.verifyTrue(isreal(b));
            testCase.verifyTrue(isreal(a));

            testCase.verifyTrue(all(isfinite(b)));
            testCase.verifyTrue(all(isfinite(a)));
        end


        function testAAFReturnsValidCoefficients(testCase)
            %% Validates LPF Coefficients Are Real, Finite, and Nonempty

            P = testCase.createDefaultParameters();
            F = ADCFilter(P);

            [b, a] = F.AAF();

            testCase.verifyNotEmpty(b);
            testCase.verifyNotEmpty(a);

            testCase.verifyTrue(isreal(b));
            testCase.verifyTrue(isreal(a));

            testCase.verifyTrue(all(isfinite(b)));
            testCase.verifyTrue(all(isfinite(a)));
        end


        function testDCRemovalMatchesExpectedHighPassButterworth(testCase)
            %% Validates DCRemoval Design Expected Butterworth HPF

            P = testCase.createDefaultParameters();
            F = ADCFilter(P);

            FcHigh = P.getValue("FcHigh"); % Cutoff Frequency
            Fs     = P.getValue("Fs"); % Sampling Frequency
            nHpf   = P.getValue("nHpf"); % Filter Order

            [bActual, aActual] = F.DCRemoval();

            [zExp, pExp, kExp] = butter(nHpf, (2*FcHigh)/Fs, "high");
            [bExpected, aExpected] = zp2tf(zExp, pExp, kExp);

            testCase.verifyEqual(bActual, bExpected, "AbsTol", 1e-12);
            testCase.verifyEqual(aActual, aExpected, "AbsTol", 1e-12);
        end


        function testAAFMatchesExpectedLowPassButterworth(testCase)
            %% Validates AAF Design Expected Butterworth LPF

            P = testCase.createDefaultParameters();
            F = ADCFilter(P);

            FcLow = P.getValue("FcLow"); % Cutoff Frequency
            Fs    = P.getValue("Fs"); % Sampling Rate
            nLpf  = P.getValue("nLpf"); % Filter Order

            [bActual, aActual] = F.AAF();

            [zExp, pExp, kExp] = butter(nLpf, (2*FcLow)/Fs, "low");
            [bExpected, aExpected] = zp2tf(zExp, pExp, kExp);

            testCase.verifyEqual(bActual, bExpected, "AbsTol", 1e-12);
            testCase.verifyEqual(aActual, aExpected, "AbsTol", 1e-12);
        end


        function testDCRemovalBehavesAsHighPass(testCase)
            %% Validates HPF Rejects DC and Passes High Frequency

            P = testCase.createDefaultParameters();
            F = ADCFilter(P);

            [b, a] = F.DCRemoval();
            
            % Evaluate frequency response at DC and near Nyquist
            %Frequency Response
            H = freqz(b, a, [0, pi]);

            H_dc = H(1);   % Response at DC
            H_high = H(2);  % Response near Nyquist

            testCase.verifyLessThan(abs(H_dc), 1e-6);
            testCase.verifyGreaterThan(abs(H_high), 0.7);
        end


        function testAAFBehavesAsLowPass(testCase)
        %% Validates AAF Passes DC/Low Frequency and Rejects High Frequency

            P = testCase.createDefaultParameters();
            F = ADCFilter(P);

            [b, a] = F.AAF();


            % Evaluate frequency response at DC and near Nyquist
            % Frequency Response 
            H = freqz(b, a, [0, pi]);

            H_dc = H(1);   % Response at DC
            H_high = H(2);  % Response near Nyquist


            testCase.verifyGreaterThan(abs(H_dc), 0.7);
            testCase.verifyLessThan(abs(H_high), 1e-3);
        end


        function testDCRemovalFilterIsStable(testCase)
            %% Validates HPF Poles Are Inside Unit Circle

            P = testCase.createDefaultParameters();
            F = ADCFilter(P);

            [~, a] = F.DCRemoval();

            poles = roots(a);

            testCase.verifyLessThan(abs(poles), ones(size(poles)));
        end


        function testAAFFilterIsStable(testCase)
            %% Validates LPF Poles Are Inside Unit Circle

            P = testCase.createDefaultParameters();
            F = ADCFilter(P);

            [~, a] = F.AAF();

            poles = roots(a);

            testCase.verifyLessThan(abs(poles), ones(size(poles)));
        end
    end

    methods (Access = private)

        function P = createDefaultParameters(~)
            %% Creates Default Parameter Object For Filter Tests

            P = Parameters();

            P.setValue("Fs", 20000); % Sampling Rate
            P.setValue("FcHigh", 20); % HPF Cutoff Frequency
            P.setValue("FcLow", 5000); % LPF Cutoff Frequency
            P.setValue("nHpf", 4); % HPF Filter Order
            P.setValue("nLpf", 6); % LPF Filter Order
        end
    end
end