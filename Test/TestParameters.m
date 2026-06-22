classdef TestParameters < matlab.unittest.TestCase
    %% ============================================================
    %% UNIT TEST SUITE FOR THE PARAMETERS CONTAINER CLASS
    %% ============================================================

    methods (Test)

        function testConstructorCreatesParameters(testCase)
            %% Validates Constructor Creates Expected Parameters
            P = Parameters();

            testCase.verifyClass(P.getMeta("Fs"), "Meta");
            testCase.verifyClass(P.getMeta("FData"), "Meta");
            testCase.verifyClass(P.getMeta("Gain"), "Meta");
            testCase.verifyClass(P.getMeta("ART"), "Meta");
        end

        function testGetValueReturnsAssignedValue(testCase)
            %% Validates getValue Returns Stored Parameter Value
            P = Parameters();

            P.setValue("Fs", 1e6);

            testCase.verifyEqual(P.getValue("Fs"), 1e6);
        end

        function testSetValueUpdatesValue(testCase)
            %% Validates setValue Updates Existing Parameter Values
            P = Parameters();

            P.setValue("Gain", 10);
            P.setValue("Gain", 25);

            testCase.verifyEqual(P.getValue("Gain"), 25);
        end

        function testGetMetaReturnsCorrectMetadata(testCase)
            %% Validates getMeta Returns Correct Metadata
            P = Parameters();

            FsMeta = P.getMeta("Fs");

            testCase.verifyEqual(FsMeta.Name, "Oversampling Frequency");
            testCase.verifyEqual(FsMeta.Unit, "Hz");
        end

        function testUnknownKeyThrowsOnGetValue(testCase)
            %% Validates getValue Rejects Unknown Keys
            P = Parameters();

            fh = @() P.getValue("WrongKey");

            testCase.verifyError(fh, 'Parameters:UnknownKey');
        end

        function testUnknownKeyThrowsOnSetValue(testCase)
            %% Validates setValue Rejects Unknown Keys
            P = Parameters();

            fh = @() P.setValue("WrongKey", 10);

            testCase.verifyError(fh, 'Parameters:UnknownKey');
        end

        function testUnknownKeyThrowsOnGetMeta(testCase)
            %% Validates getMeta Rejects Unknown Keys
            P = Parameters();

            fh = @() P.getMeta("WrongKey");

            testCase.verifyError(fh, 'Parameters:UnknownKey');
        end

        function testSetValueUsesMetaValidation(testCase)
            %% Validates Parameter Validation Is Enforced
            P = Parameters();

            fh = @() P.setValue("Fs", -1);

            testCase.verifyError(fh, 'Meta:ValidationFailed');
        end

        function testDefaultValueIsNaN(testCase)
            %% Validates Parameters Start Unassigned
            P = Parameters();

            testCase.verifyTrue(isnan(P.getValue("Fs")));
        end

    end
end