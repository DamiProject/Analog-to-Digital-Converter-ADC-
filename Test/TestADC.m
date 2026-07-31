classdef TestADC < matlab.unittest.TestCase
    %% ==================================
    %% UNIT TEST SUITE FOR THE ADC CLASS
    %% ==================================

    methods (Test)

        function testConstructorStoresParametersObject(testCase)
            %% Validates Constructor Stores Parameters Handle

            P = testCase.createDefaultParameters();
            A = ADC(P);

            testCase.verifySameHandle(A.Parameters, P);
        end

        function testSamplerDownsamplesToADCRate(testCase)
            %% Validates ADC Sampling Selects Samples at Fs/DF
            P = testCase.createDefaultParameters();
            A = ADC(P);

            Fs = P.getValue("Fs");  % High-rate simulation frequency
            DF = P.getValue("DF");  % ADC sampling factor

            N = 13;

            % Row-vector input also validates column-vector conversion.
            x = 10 * (1:N);

            [y, SampleIndex, ADCSamplingFrequency] = A.Sampler(x);

            expectedIndex = (1:DF:N)';

            expectedOutput = x(expectedIndex);
            expectedOutput = expectedOutput(:);

            expectedADCSamplingFrequency = Fs / DF;

            testCase.verifySize(y, [numel(expectedIndex), 1]);
            testCase.verifySize( ...
            SampleIndex, [numel(expectedIndex), 1]);

            testCase.verifyEqual(y, expectedOutput);
            testCase.verifyEqual(SampleIndex, expectedIndex);

            testCase.verifyEqual( ...
            ADCSamplingFrequency, ...
            expectedADCSamplingFrequency);
        end

        function testMidtreadUsesCompleteCodebook(testCase)
            %% Validates Midtread Reconstruction Levels and Indices

            P = testCase.createDefaultParameters();
            A = ADC(P);

            Vfs = P.getValue("Vfs");
            NumBits = P.getValue("NumBits");

            Delta = Vfs / 2^NumBits;

            expectedIndices = (0:2^NumBits-1)';
            expectedLevels = ...
                -(Vfs/2) + expectedIndices * Delta;

            % Row-vector input also validates column-vector conversion.
            x = expectedLevels';

            [y, Indices, Error] = A.Midtread(x);

            testCase.verifySize(y, [2^NumBits 1]);
            testCase.verifySize(Indices, [2^NumBits 1]);
            testCase.verifySize(Error, [2^NumBits 1]);

            testCase.verifyEqual(y, expectedLevels, ...
                "AbsTol", 1e-12);

            testCase.verifyEqual(Indices, expectedIndices);

            testCase.verifyEqual(Error, zeros(size(expectedLevels)), ...
                "AbsTol", 1e-12);

            % Confirms every available N-bit code is represented.
            testCase.verifyEqual(numel(unique(Indices)), 2^NumBits);

            % Midtread must contain a zero reconstruction level.
            testCase.verifyTrue(any(abs(y) < 1e-12));
        end

        function testMidtreadRangeMatchesTwosComplementCoding(testCase)
            %% Validates Asymmetric Midtread Endpoints for N-Bit Coding

            P = testCase.createDefaultParameters();
            A = ADC(P);

            Vfs = P.getValue("Vfs");
            NumBits = P.getValue("NumBits");

            Delta = Vfs / 2^NumBits;
            expectedLevels = ...
                -(Vfs/2) + (0:2^NumBits-1)' * Delta;

            [y, ~, ~] = A.Midtread(expectedLevels);

            % Full negative endpoint is represented.
            testCase.verifyEqual(y(1), -(Vfs/2), ...
                "AbsTol", 1e-12);

            % Positive endpoint is one LSB below positive full scale.
            testCase.verifyEqual(y(end), (Vfs/2)-Delta, ...
                "AbsTol", 1e-12);
        end

        function testMidtreadClipsOutOfRangeInputs(testCase)
            %% Validates Midtread Saturation at Minimum and Maximum Codes

            P = testCase.createDefaultParameters();
            A = ADC(P);

            x = [
                -10
                -4
                -3.6
                 0
                 3.4
                 4
                10
            ];

            [y, Indices, Error] = A.Midtread(x);

            expectedOutput = [
                -4
                -4
                -4
                 0
                 3
                 3
                 3
            ];

            expectedIndices = [
                0
                0
                0
                4
                7
                7
                7
            ];

            testCase.verifyEqual(y, expectedOutput, ...
                "AbsTol", 1e-12);

            testCase.verifyEqual(Indices, expectedIndices);

            testCase.verifyEqual(Error, y-x, ...
                "AbsTol", 1e-12);
        end

        function testMidtreadGranularErrorDoesNotExceedHalfLSB(testCase)
            %% Validates Midtread Error Inside Non-Overload Region

            P = testCase.createDefaultParameters();
            A = ADC(P);

            Vfs = P.getValue("Vfs");
            NumBits = P.getValue("NumBits");

            Delta = Vfs / 2^NumBits;

            % Excludes the upper overload region above the final threshold.
            x = linspace(-(Vfs/2), (Vfs/2)-(Delta/2), 1001)';

            [~, ~, Error] = A.Midtread(x);

            testCase.verifyLessThanOrEqual ...
            (max(abs(Error)), (Delta/2)+1e-12);
        end

        function testMidriseUsesCompleteCodebook(testCase)
            %% Validates Midrise Half-LSB Levels and Indices

            P = testCase.createDefaultParameters();
            A = ADC(P);

            Vfs = P.getValue("Vfs");
            NumBits = P.getValue("NumBits");

            Delta = Vfs / 2^NumBits;

            expectedIndices = (0:2^NumBits-1)';
            expectedLevels = ...
                -(Vfs/2) + (expectedIndices+0.5) * Delta;

            [y, Indices, Error] = A.Midrise(expectedLevels);

            testCase.verifySize(y, [2^NumBits 1]);
            testCase.verifySize(Indices, [2^NumBits 1]);
            testCase.verifySize(Error, [2^NumBits 1]);

            testCase.verifyEqual(y, expectedLevels, ...
                "AbsTol", 1e-12);

            testCase.verifyEqual(Indices, expectedIndices);

            testCase.verifyEqual(Error, zeros(size(expectedLevels)), ...
                "AbsTol", 1e-12);

            % Midrise has no zero reconstruction level.
            testCase.verifyFalse(any(abs(y) < 1e-12));

            testCase.verifyEqual(numel(unique(Indices)), 2^NumBits);
        end

        function testMidriseClipsOutOfRangeInputs(testCase)
            %% Validates Midrise Saturation at Endpoint Levels

            P = testCase.createDefaultParameters();
            A = ADC(P);

            x = [
                -10
                -4
                -3.5
                 0
                 3.5
                 4
                10
            ];

            [y, Indices, Error] = A.Midrise(x);

            expectedOutput = [
                -3.5
                -3.5
                -3.5
                 0.5
                 3.5
                 3.5
                 3.5
            ];

            expectedIndices = [
                0
                0
                0
                4
                7
                7
                7
            ];

            testCase.verifyEqual(y, expectedOutput, ...
                "AbsTol", 1e-12);

            testCase.verifyEqual(Indices, expectedIndices);

            testCase.verifyEqual(Error, y-x, ...
                "AbsTol", 1e-12);
        end

        function testMidriseGranularErrorDoesNotExceedHalfLSB(testCase)
            %% Validates Midrise Error Across Nominal Input Range

            P = testCase.createDefaultParameters();
            A = ADC(P);

            Vfs = P.getValue("Vfs");
            NumBits = P.getValue("NumBits");

            Delta = Vfs / 2^NumBits;

            x = linspace(-(Vfs/2), Vfs/2, 1001)';

            [~, ~, Error] = A.Midrise(x);

            testCase.verifyLessThanOrEqual ...
            (max(abs(Error)), (Delta/2)+1e-12);
        end
    end

    methods (Access = private)

        function P = createDefaultParameters(testCase)
            %% Creates Default Parameters Object For ADC Unit Tests

            P = Parameters();

            P.setValue("Fs", 48000);
            P.setValue("Vfs", 8.0);
            P.setValue("NumBits", 3);
            P.setValue("DF", 4);

            % Confirm required parameters are valid and readable.
            testCase.verifyEqual(P.getValue("Fs"), 48000);
            testCase.verifyEqual(P.getValue("Vfs"), 8.0);
            testCase.verifyEqual(P.getValue("NumBits"), 3);
            testCase.verifyEqual(P.getValue("DF"), 4);
        end
    end
end
