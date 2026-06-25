classdef TestAGC < matlab.unittest.TestCase
    %% ==================================
    %% UNIT TEST SUITE FOR THE AGC CLASS
    %% ==================================

    methods (Test)

        function testConstructorStoresParametersObject(testCase)
            %% Validates Constructor Stores Parameters Handle

            P = testCase.createDefaultParameters();
            A = AGC(P);

            testCase.verifySameHandle(A.Parameters, P);
        end

        function testOutputTimeAndHistoryHaveCorrectSize(testCase)
            %% Validates Output, Time Vector, and History Signal Sizes

            P = testCase.createDefaultParameters();
            A = AGC(P);

            Fs = P.getValue("Fs");
            N = 1000;
            tExpected = (0:N-1)' / Fs;

            x = 0.2 * sin(2*pi*20*tExpected);

            [y, t, History] = A.GainControl(x);

            testCase.verifySize(y, [N 1]);
            testCase.verifySize(t, [N 1]);
            testCase.verifyEqual(t, tExpected, "AbsTol", 1e-12);

            testCase.verifySize(History.Gain, [N 1]);
            testCase.verifySize(History.GateGain, [N 1]);
            testCase.verifySize(History.EffectiveGain, [N 1]);
            testCase.verifySize(History.Envelope, [N 1]);
            testCase.verifySize(History.ProjectedEnvelope, [N 1]);
            testCase.verifySize(History.AGCSignal, [N 1]);

            testCase.verifyTrue(all(isfinite(y)));
            testCase.verifyTrue(all(isfinite(History.Gain)));
            testCase.verifyTrue(all(isfinite(History.GateGain)));
            testCase.verifyTrue(all(isfinite(History.EffectiveGain)));
            testCase.verifyTrue(all(isfinite(History.Envelope)));
            testCase.verifyTrue(all(isfinite(History.ProjectedEnvelope)));
            testCase.verifyTrue(all(isfinite(History.AGCSignal)));
        end

        function testSilentInputClosesNoiseGate(testCase)
            %% Validates Noise Gate Decays Toward Closed 
            %% State During Silence

            P = testCase.createDefaultParameters();
            A = AGC(P);

            N = 1000;
            x = zeros(N, 1);

            [y, ~, History] = A.GainControl(x);

            testCase.verifyEqual(y, zeros(N, 1), "AbsTol", 1e-12);

            % Gate should decay from its initial open value toward zero.
            testCase.verifyLessThan ...
            (History.GateGain(end), History.GateGain(1));

            % Gate gain must remain inside valid gate range.
            testCase.verifyGreaterThanOrEqual(min(History.GateGain), 0);
            testCase.verifyLessThanOrEqual(max(History.GateGain), 1);
        end

        function testLargeActiveSignalReducesAGCGain(testCase)
            %% Validates AGC Reduces Gain When Projected 
            %% Envelope Is Too High

            P = testCase.createDefaultParameters();
            A = AGC(P);

            N = 1500;

            % Large active signal should exceed upper AGC limit.
            x = 2.0 * ones(N, 1);

            [~, ~, History] = A.GainControl(x);

            % Gain should reduce below initial gain of 1.0.
            testCase.verifyLessThan(History.Gain(end), 1.0);

            % Gain must remain inside AGC gain bounds.
            testCase.verifyGreaterThanOrEqual(min(History.Gain), 0.1);
            testCase.verifyLessThanOrEqual(max(History.Gain), 10.0);
        end

        function testSmallActiveSignalIncreasesAGCGain(testCase)
            %% Validates AGC Increases Gain When 
            %% Projected Envelope Is Too Low

            P = testCase.createDefaultParameters();
            A = AGC(P);

            N = 1500;

            % Small but active signal: above noise threshold, below 
            % lower AGC limit.
            x = 0.02 * ones(N, 1);

            [~, ~, History] = A.GainControl(x);

            % Gain should increase above initial gain of 1.0.
            testCase.verifyGreaterThan(History.Gain(end), 1.0);

            % Gain must remain inside AGC gain bounds.
            testCase.verifyGreaterThanOrEqual(min(History.Gain), 0.1);
            testCase.verifyLessThanOrEqual(max(History.Gain), 10.0);
        end

        function testOutputEqualsInputTimesEffectiveGain(testCase)
            %% Validates Final Output, Uses Combined AGC Gain and Gate Gain

            P = testCase.createDefaultParameters();
            A = AGC(P);

            Fs = P.getValue("Fs");
            N = 1000;
            t = (0:N-1)' / Fs;

            x = 0.5 * sin(2*pi*30*t);

            [y, ~, History] = A.GainControl(x);

            expectedOutput = x .* History.EffectiveGain;

            testCase.verifyEqual(y, expectedOutput, "AbsTol", 1e-12);
        end

        function testEffectiveGainEqualsGainTimesGateGain(testCase)
            %% Validates Effective Gain Is AGC Gain Multiplied By Gate Gain

            P = testCase.createDefaultParameters();
            A = AGC(P);

            Fs = P.getValue("Fs");
            N = 1000;
            t = (0:N-1)' / Fs;

            x = 0.3 * sin(2*pi*50*t);

            [~, ~, History] = A.GainControl(x);

            expectedEffectiveGain = History.Gain .* History.GateGain;

            testCase.verifyEqual ...
            (History.EffectiveGain, expectedEffectiveGain, ...
                "AbsTol", 1e-12);
        end

        function testAGCSignalEqualsInputTimesGain(testCase)
            %% Validates AGCSignal Stores Signal Before Noise Gate

            P = testCase.createDefaultParameters();
            A = AGC(P);

            Fs = P.getValue("Fs");
            N = 1000;
            t = (0:N-1)' / Fs;

            x = 0.4 * sin(2*pi*25*t);

            [~, ~, History] = A.GainControl(x);

            expectedAGCSignal = x .* History.Gain;

            testCase.verifyEqual(History.AGCSignal, expectedAGCSignal, ...
                "AbsTol", 1e-12);
        end

        function testResetRestoresInitialAGCState(testCase)
            %% Validates Reset Restores AGC Internal State

            P = testCase.createDefaultParameters();

            A1 = AGC(P);
            A2 = AGC(P);

            N = 1000;

            % First disturb A1 state using a large signal.
            disturbance = 2.0 * ones(N, 1);
            A1.GainControl(disturbance);

            % Reset A1.
            A1.reset();

            % Compare reset object against a fresh AGC object.
            x = 0.2 * ones(N, 1);

            [y1, t1, H1] = A1.GainControl(x);
            [y2, t2, H2] = A2.GainControl(x);

            testCase.verifyEqual(y1, y2, "AbsTol", 1e-12);
            testCase.verifyEqual(t1, t2, "AbsTol", 1e-12);

            testCase.verifyEqual(H1.Gain, H2.Gain, "AbsTol", 1e-12);
            testCase.verifyEqual ...
            (H1.GateGain, H2.GateGain, "AbsTol", 1e-12);
            testCase.verifyEqual ...
            (H1.EffectiveGain, H2.EffectiveGain, "AbsTol", 1e-12);
            testCase.verifyEqual ...
            (H1.Envelope, H2.Envelope, "AbsTol", 1e-12);
            testCase.verifyEqual ...
            (H1.ProjectedEnvelope, H2.ProjectedEnvelope, "AbsTol", 1e-12);
            testCase.verifyEqual ...
            (H1.AGCSignal, H2.AGCSignal, "AbsTol", 1e-12);
        end
    end

    methods (Access = private)

        function P = createDefaultParameters(testCase)
            %% Creates Default Parameters Object For AGC Unit Tests

            P = Parameters();

            P.setValue("Fs", 1000);
            P.setValue("Anf", 1e-3);
            P.setValue("Vfs", 1.0);

            P.setValue("EnvAttack", 0.005);
            P.setValue("EnvRelease", 0.020);

            P.setValue("GainAttack", 0.005);
            P.setValue("GainRelease", 0.020);

            P.setValue("GateAttack", 0.005);
            P.setValue("GateRelease", 0.020);

            % Confirm required parameters are valid and readable.
            testCase.verifyEqual(P.getValue("Fs"), 1000);
            testCase.verifyEqual(P.getValue("Anf"), 1e-3);
            testCase.verifyEqual(P.getValue("Vfs"), 1.0);
        end
    end
end