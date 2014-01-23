classdef Task1Logic < handle
%
% Implements logic specific to Gerine her second experiment.
%
% All MSGs say the image is at (Left, Top) = (279, 34)
% The images are (Width, Height) = (465, 700)
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
        
        
        function obj = Task1Logic()
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
                    
                    % The "End of Picture" message is always the one immediately after the "Picture" message.
                    [~, offset] = min(abs(data(t).samples(:, 1) - double(data(t).messages(m + 1).time)));
                    
                    % Check that to be sure                    
                    if ~strcmp(data(t).messages(m + 1).message, '# Message: End of Picture')
                      error('Found "%s" message instead of "End of Picture".', data(t).messages(m + 1).message);
                    end
                    
                    s = 1;
                    
                    for p = 1:length(tokens)
                        left = str2double(tokens{p}{1});
                        top = str2double(tokens{p}{2});
                        width = 465;
                        height = 700;                        

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
