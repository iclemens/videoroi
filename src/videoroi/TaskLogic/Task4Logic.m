classdef Task4Logic < handle
%
% Implements logic specific to Gerine her fourth experiment.
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
        
        
        function obj = Task4Logic()
        end


        function data = parseStimulusMsgs(~, data)
            % Find the stimuli presented in each trial
            
            frameData = idf_parse_frame_msgs(data);            
            
            for t = 1:length(data)
                frameNrs = unique(frameData(t).frames);
                frameNrs(isnan(frameNrs)) = [];

                s = 1;
                
                for f = frameNrs'
                    frameSamples = find(frameData(t).frames == f);
                    
                    data(t).stimulus(s).name = frameData(t).movie;
                    data(t).stimulus(s).frame = f;
                    data(t).stimulus(s).onset = frameSamples(1);
                    data(t).stimulus(s).offset = frameSamples(end);
                    data(t).stimulus(s).position = [0 0 1024 768];
                    s = s + 1;
                end
            end
        end
    end
end
