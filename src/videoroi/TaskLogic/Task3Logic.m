classdef Task3Logic < handle
%
% Implements logic specific to Gerine her third experiment.
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
        
        
        function obj = Task3Logic()
        end


        function descr = getTrialDescription(~, stimuli)
          descr = lower(stimuli(1).name);          
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
                        top = str2double(tokens{p}{1});
                        left = str2double(tokens{p}{2});
                        
                        width = 466;
                        height = 350;                        

                        data(t).stimulus(s).name = tokens{p}{3};
                        data(t).stimulus(s).frame = 0;
                        data(t).stimulus(s).onset = onset;
                        data(t).stimulus(s).offset = offset;
                        data(t).stimulus(s).position = [top left width height];

                        s = s + 1;
                    end                    
                end
            end
        end
    end
end
