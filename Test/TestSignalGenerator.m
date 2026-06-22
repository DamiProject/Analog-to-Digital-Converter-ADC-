classdef TestSignalGenerator < matlab.unittest.TestCase
    %% =========================================
    %% UNIT TEST SUITE FOR THE SIGNAL GENERATOR
    %% =========================================

    methods (Test)

        function testConstructorStoresParametersObject(testCase)
            %% Validates Constructor Stores The Parameters Object
            P = testCase.createDefaultParameters();
            SG = SignalGenerator(P);
            
            testCase.verifySameHandle(SG.Parameters, P);
        end

        function testTimeVectorProperties(testCase)
            %% Validates Time Vector Length, Shape, Start, and End Points
            P = testCase.createDefaultParameters();
            SG = SignalGenerator(P);

            [~, t] = SG.GenNoisySignal();

            Fs = P.getValue("Fs");
            Dur = P.getValue("Dur");
            expectedSamples = Fs * Dur;
            expectedTime = (0:1/Fs:Dur-1/Fs)';

            % Comprehensive structural and structural match
            testCase.verifySize(t, [expectedSamples 1]);
            testCase.verifyEqual(t, expectedTime, "AbsTol", 1e-12);
        end

        function testOutputSignalIsColumnAndMatchesTimeLength(testCase)
            %% Validates Generated Signal Has Same Shape As Time Vector
            P = testCase.createDefaultParameters();
            SG = SignalGenerator(P);

            [Inp_Sig, t] = SG.GenNoisySignal();

            testCase.verifySize(Inp_Sig, size(t));
            testCase.verifyTrue(iscolumn(Inp_Sig));
            testCase.verifyTrue(iscolumn(t));
        end

        function testSignalWithoutAWGNMatchesExpectedSignal(testCase)
            %% Validates Deterministic Composite Signal Against Formula
            P = testCase.createDefaultParameters();
            P.setValue("Anf", 0); % Disable AWGN noise floor

            SG = SignalGenerator(P);
            [Inp_Sig, t] = SG.GenNoisySignal();

            expectedSignal = testCase.computeExpectedSignal(P, t);

            testCase.verifyEqual(Inp_Sig, expectedSignal, "AbsTol", 1e-12);
        end

        function testNoiseFloorIsRepeatableWithControlledRNG(testCase)
            %% Validates AWGN Floor Can Be Tested By Controlling MATLAB RNG
            P = testCase.createDefaultParameters();
            P.setValue("Anf", 0.02);

            Fs = P.getValue("Fs");
            Dur = P.getValue("Dur");
            expectedTime = (0:1/Fs:Dur-1/Fs)';

            SG = SignalGenerator(P);

            % Establish clean environment boundary condition
            oldRngState = rng;
            cleanupObj = onCleanup(@() rng(oldRngState));

            % Generate expected noise floor from known RNG state
            rng(7, "twister");
            expectedNoiseFloor = P.getValue("Anf") * randn(size(expectedTime));
            expectedSignal = testCase.computeExpectedSignal(P, expectedTime, expectedNoiseFloor);

            % Reset RNG so SignalGenerator uses the exact same noise sequence
            rng(7, "twister");
            [sig1, t1] = SG.GenNoisySignal();

            % Reset again to prove predictability
            rng(7, "twister");
            [sig2, t2] = SG.GenNoisySignal();

            testCase.verifyEqual(t1, expectedTime, "AbsTol", 1e-12);
            testCase.verifyEqual(t2, expectedTime, "AbsTol", 1e-12);

            testCase.verifyEqual(sig1, sig2, "AbsTol", 1e-12);
            testCase.verifyEqual(sig1, expectedSignal, "AbsTol", 1e-12);
        end

        function testSignalChangesWhenNoiseFloorIsEnabled(testCase)
            %% Validates Nonzero Noise Floor Affects The Composite Signal
            Pclean = testCase.createDefaultParameters();
            Pclean.setValue("Anf", 0);

            Pnoisy = testCase.createDefaultParameters();
            Pnoisy.setValue("Anf", 0.02);

            SGclean = SignalGenerator(Pclean);
            SGnoisy = SignalGenerator(Pnoisy);

            oldRngState = rng;
            cleanupObj = onCleanup(@() rng(oldRngState)); 

            rng(11, "twister");
            cleanSignal = SGclean.GenNoisySignal();

            rng(11, "twister");
            noisySignal = SGnoisy.GenNoisySignal();

            testCase.verifyNotEqual(noisySignal, cleanSignal);
        end

       function testFadeReducesDataSignalAmplitude(testCase)
           %% Validates Exponential Fade Reduces Data Signal Amplitude

           P = testCase.createDefaultParameters();
           SG = SignalGenerator(P);
           [~, t, Components] = SG.GenNoisySignal();

           EST = P.getValue("EST");

           preFadeIdx = t < EST;
           fadeIdx = find(t >= EST);

           lateFadeIdx = fadeIdx(round(numel(fadeIdx)/2):end);

           preFadeMaxAmplitude = ...
           max(abs(Components.DataSignal(preFadeIdx)));
           lateFadeMaxAmplitude = ...
           max(abs(Components.DataSignal(lateFadeIdx)));

           testCase.verifyLessThan ...
           (lateFadeMaxAmplitude, preFadeMaxAmplitude);
       end

      function testGaussianBurstIncreasesDataSignalAmplitude(testCase)
          %% Validates Gaussian Burst Increases Data Signal Amplitude
          P = testCase.createDefaultParameters();      
          SG = SignalGenerator(P);
          [~, ~, Components] = SG.GenNoisySignal();
          Ad = P.getValue("Ad");
          maxDataAmplitude = max(abs(Components.DataSignal));
          testCase.verifyGreaterThan(maxDataAmplitude, Ad);
      end
 end

    methods (Access = private)

        function P = createDefaultParameters(~)
            %% Creates A Fresh, Isolated Parameter Object Instantiation
            P = Parameters();

            P.setValue("Fs", 1000);        % Oversampling frequency, Hz
            P.setValue("Dur", 0.02);       % Duration, seconds
            P.setValue("Aburst", 0.5);     % Gaussian burst amplitude
            P.setValue("mu", 0.006);       % Gaussian burst peak location
            P.setValue("Sigma", 0.002);    % Gaussian burst width
            P.setValue("Ad", 1.0);         % Base envelope amplitude
            P.setValue("Lambda", 30);      % Decay constant
            P.setValue("EST", 0.012);      % Exponential decay start time
            P.setValue("FData", 50);       % Data frequency, Hz
            P.setValue("An", 0.1);         % Out-of-band noise amplitude
            P.setValue("Fnoise", 300);    % Out-of-band noise frequency, Hz
            P.setValue("Anf", 0);          % AWGN floor amplitude
            P.setValue("DC", 0.25);        % DC offset
        end

        function expectedSignal = computeExpectedSignal(~, P, t, NoiseFloor)
            if nargin < 4
                NoiseFloor = zeros(size(t));
            end
            
            Aburst = P.getValue("Aburst");
            mu = P.getValue("mu");
            Sigma = P.getValue("Sigma");
            Ad = P.getValue("Ad");

            BurstEnvelope = Aburst * exp(-((t - mu).^2) / (2 * Sigma^2));
            Envelope = Ad + BurstEnvelope;

            Lambda = P.getValue("Lambda");
            EST = P.getValue("EST");

            fade_idx = t >= EST;
            if any(fade_idx)
                first_fade_idx = find(fade_idx, 1);
                start_val = Envelope(first_fade_idx);
                FadeEnvelope = exp(-Lambda * (t(fade_idx) - EST));
                Envelope(fade_idx) = start_val * FadeEnvelope;
            end

            FData = P.getValue("FData");
            DataSignal = sin(2*pi*FData*t) .* Envelope;

            An = P.getValue("An");
            Fnoise = P.getValue("Fnoise");
            NoiseSignal = An * sin(2*pi*Fnoise*t);

            DC = P.getValue("DC");

            expectedSignal = DC + DataSignal + NoiseSignal + NoiseFloor;
        end

    end
end
