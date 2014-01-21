classdef Task2Logic < handle
%
% Implements logic specific to Gerine her second experiment.
%
% Four faces in a 2x2 grid.
%
% Usual image locations:
%  (Left, Top) = (276, 34)
%  (Left, Top) = (516, 34)
%  (Left, Top) = (276, 384)
%  (Left, Top) = (516, 384)
%
% Image dimensions (Width, Height) = (232, 350)
%
% X = 1024 = 276 | [232] | 8 | [232] | 276
% Y =  768 =  34 | [350] | 0 | [350] | 34
%

    % Settings
    properties(Access = private)
 
        % Minimal saccade velocity (rad / s)
        saccadeThreshold = degtorad(45);

        % Maximum allowable deviation from initial saccade direction (rad)
        extensionAngleThreshold = 0.5 * pi;
        
        % Minimum duration of fixation (in seconds)
        minimumFixationDuration = 0.1;
        
        % Discard time period after scene change (in seconds)
        discardDataAfterChange = 0.1;
    end

    methods(Access = public)
        
        
        function obj = Task2Logic()
        end


        function descr = getTrialDescription(~, stimuli)
          name = lower(stimuli(1).name);
          
          try
            tokens = regexp(name, '[a-z]+[0-9]+_([0-9]+)_([a-z]+)_([a-z]+)_([a-z]+)', 'tokens');
            tokens = tokens{1};
          
            num = str2double(tokens{1});
          
            descr = sprintf('%02d/%s/%s', num, tokens{2}, tokens{3});
          catch e
            descr = name;
          end
        end


        function data = parseStimulusMsgs(~, data)            
            expr = 'Picture: Left: ([0-9]*) top: ([0-9]*) Name: ([^\s])*';

            for t = 1:length(data)
                for m = 1:length(data(t).messages)
                    try
                        tokens = regexp(data(t).messages(m).message, expr, 'tokens');
                    catch e
                        continue;
                    end
                    
                    % Not a stimulus message, or offset cannot be computed
                    if numel(tokens) == 0 || numel(data(t).messages) <= m
                        continue;
                    end
                    
                    [~, onset] = min(abs(data(t).samples(:, 1) - double(data(t).messages(m).time)));
                    [~, offset] = min(abs(data(t).samples(:, 1) - double(data(t).messages(m + 1).time)));
                    
                    s = 1;
                    
                    for p = 1:length(tokens)
                        left = str2double(tokens{p}{1});
                        top = str2double(tokens{p}{2});
                        width = 232;
                        height = 350;                        

                        data(t).stimulus(s).name = tokens{p}{3};
                        data(t).stimulus(s).frame = 0;
                        data(t).stimulus(s).onset = onset;
                        data(t).stimulus(s).offset = offset;
                        data(t).stimulus(s).position = [left top width height];

                        s = s + 1;
                    end                    
                end
            end
        end
    end
end
