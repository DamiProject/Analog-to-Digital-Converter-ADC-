classdef Parameters < handle
    %% ===================================================
    %% CONTAINER OF META OBJECTS FOR ADC PARAMETERS
    %% ===================================================

    properties (Access = private)
        % Hidden storage to protect metadata integrity
        Params struct
    end

    methods
        function obj = Parameters()
            Schema = obj.GetSchema();
            obj.Params = struct();

            for k = 1:numel(Schema)
                S = Schema{k}; 

                if isfield(S, 'Unit') && ~isempty(S.Unit) && ~ismissing(S.Unit) && S.Unit ~= ""
                    obj.Params.(S.Key) = Meta( ...
                        S.Name, ...
                        S.Validator, ...
                        S.DataType, ...
                        S.Unit);
                else
                    obj.Params.(S.Key) = Meta( ...
                        S.Name, ...
                        S.Validator, ...
                        S.DataType);
                end
            end
        end
        
        function PromptUser(obj)
            names = fieldnames(obj.Params);
            for k = 1:numel(names)
                param = obj.Params.(names{k});
                while true
                    try
                        if isprop(param, 'Unit') && ~ismissing(param.Unit) && param.Unit ~= ""
                            promptStr = sprintf("Enter %s (%s): ", param.Name, param.Unit);
                        else
                            promptStr = sprintf("Enter %s: ", param.Name);
                        end
                        
                        value = input(promptStr);
                        param.Value = value;
                        break
                    catch ME
                        fprintf(2, "Error: %s\n", ME.message);
                    end
                end
            end
        end
    end

    %% ===================================================
    %% CUSTOM INDEXING OVERLOADS FOR DIRECT SYNTAX ACCESS
    %% ===================================================
    methods (Access = protected)
        %% Intercept Property Reference (Reading: value = obj.Fs)
        function varargout = subsref(obj, s)
            switch s(1).type
                case '.'
                    % Handle standard internal method execution (like obj.PromptUser())
                    if ismethod(obj, s(1).subs)
                        if nargout > 0
                            [varargout{1:nargout}] = builtin('subsref', obj, s);
                        else
                            builtin('subsref', obj, s);
                        end
                        return;
                    end
                    
                    % Route custom parameter property reads directly to .Value
                    if isfield(obj.Params, s(1).subs)
                        % Extract Meta object reference
                        metaObj = obj.Params.(s(1).subs);
                        
                        % Support trailing chain indices like obj.Fs or obj.Fs.Unit
                        if numel(s) > 1
                            [varargout{1:nargout}] = subsref(metaObj, s(2:end));
                        else
                            varargout{1} = metaObj.Value;
                        end
                    else
                        % Default fallback error for non-existent properties
                        error('Parameters:InvalidProperty', ...
                            'Property "%s" does not exist.', s(1).subs);
                    end
                    
                otherwise
                    % Handle array syntax tracking fallbacks (e.g. obj(1))
                    [varargout{1:nargout}] = builtin('subsref', obj, s);
            end
        end

        %% Intercept Property Assignment (Writing: obj.Fs = 10)
        function obj = subsasgn(obj, s, val)
            switch s(1).type
                case '.'
                    if isfield(obj.Params, s(1).subs)
                        metaObj = obj.Params.(s(1).subs);
                        
                        % Support standard parameter value writes or explicit property modifications
                        if numel(s) > 1
                            subsasgn(metaObj, s(2:end), val);
                        else
                            metaObj.Value = val;
                        end
                    else
                        error('Parameters:InvalidProperty', ...
                            'Property "%s" does not exist.', s(1).subs);
                    end
                otherwise
                    obj = builtin('subsasgn', obj, s, val);
            end
        end
    end
    
    methods
        %% Expose dynamic names to workspace tab-completion & properties()
        function p = properties(obj)
            p = fieldnames(obj.Params);
        end
        
        function p = propertynames(obj)
            p = fieldnames(obj.Params);
        end
    end

    methods (Static, Access = private)
        function Schema = GetSchema()
            Schema = {
                struct('Key', "Fs", 'Name', "Sampling Frequency", 'Validator', @mustBePositive, 'DataType', "double", 'Unit', "Hz")
                struct('Key', "FData", 'Name', "Data Frequency", 'Validator', @mustBePositive, 'DataType', "double", 'Unit', "Hz")
                struct('Key', "Fnoise", 'Name', "Noise Frequency", 'Validator', @mustBePositive, 'DataType', "double", 'Unit', "Hz")
                struct('Key', "FcLow", 'Name', "Low Cutoff Frequency", 'Validator', @mustBePositive, 'DataType', "double", 'Unit', "Hz")
                struct('Key', "FcHigh", 'Name', "High Cutoff Frequency", 'Validator', @mustBePositive, 'DataType', "double", 'Unit', "Hz")
                struct('Key', "DC", 'Name', "DC Amplitude", 'Validator', @mustBePositive, 'DataType', "double", 'Unit', "Volts")
                struct('Key', "DF", 'Name', "Downsampling Factor", 'Validator', @mustBePositive, 'DataType', "double")
                struct('Key', "TP", 'Name', "AGC Target Peak", 'Validator', @mustBePositive, 'DataType', "double")
                struct('Key', "Gain", 'Name', "Initial AGC Gain", 'Validator', @mustBePositive, 'DataType', "double")
                struct('Key', "ART", 'Name', "AGC Release Time", 'Validator', @mustBePositive, 'DataType', "double", 'Unit', "Seconds")
                struct('Key', "AAT", 'Name', "AGC Attack Time", 'Validator', @mustBePositive, 'DataType', "double", 'Unit', "Seconds")
            };
        end
    end
end
