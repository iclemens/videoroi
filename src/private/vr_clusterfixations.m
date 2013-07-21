function output = vr_clusterfixations(cfg, data)
% VR_CLUSTERFIXATIONS  Clusters fixations by region of interest.
    
    vr_initialize();

    % Select function to use for unit conversion
    func = @(x) x;
    if(strcmp(cfg.units, 'us'))
        func = @(x) round(x);
    elseif(strcmp(cfg.units, 'ms'))
        func = @(x) round(x / 1000.0);
    elseif(strcmp(cfg.units, 's'))
        func = @(x) round(x / 1000.0) / 1000.0;
    end
    
    
    output = struct();
    output.cfg = cfg;
    if(isfield(data, 'cfg')), output.cfg.previous = data.cfg; end;
    output.labels = {'stimulus_nr', 'roi_nr', 'f_fix_start', 't_fix_start', 'f_fix_stop', 't_fix_stop', 'fix_duration', 'overlap'};
    
    output.trials = cell(1, length(data.trials));    

    % Find relevant columns
    col_fixation_mask = strcmp(data.labels, 'fixation_mask');   %2
    col_stimulus_nr = strcmp(data.labels, 'stimulus_nr');       %3
    col_roi_nr = strcmp(data.labels, 'roi_nr');             %4
    col_frame_nr = strcmp(data.labels, 'frame_nr');         %5
    col_overlap = strcmp(data.labels, 'overlap');
    
    clusterRunning = false;
    clusterStarted = 1;    
    
    for t = 1:length(data.trials)
        nsamples = length(data.time{t});
        
        for s = 1:nsamples
            % Fixation cluster started
            if(~clusterRunning && data.trials{t}(s, col_fixation_mask))
                clusterRunning = true;
                clusterStarted = s;
                regionStarted = s;
                mark = size(output.trials{t}, 1) + 1;
            end

            % Region of interest has changed
            if(clusterRunning && s > 1 && data.trials{t}(s - 1, col_stimulus_nr) > 0 && ...
                    ( ...                        
                        (data.trials{t}(s, col_roi_nr) ~= data.trials{t}(regionStarted, col_roi_nr)) || ... % Region has changed
                        ~(data.trials{t}(s, col_fixation_mask)) || ...     % Not fixating anymore
                        s == nsamples ...   % Last sample
                    ))

                %
                % The start time of a fixation is in the middle of the
                % first sample of the fixation and the one before it.
                %
                % For example:
                %  Sample time in ms:  2   4   6   8
                %  Fixation flag:      -   -   F   F
                %
                % In this case the fixation starts at time 5.
                % A similar trick is applied to the stop-times.
                %
                if(regionStarted > 1)
                    startTime = mean(data.time{t}(regionStarted - [0 1]));
                else
                    startTime = data.time{t}(regionStarted);
                end;

                if(s < nsamples)
                    stopTime = mean(data.time{t}(s - [0 1]));
                else
                    stopTime = data.time{t}(s);
                end;

                duration = stopTime - startTime;

                startFrame = data.trials{t}(regionStarted, col_frame_nr);
                stopFrame = data.trials{t}(s, col_frame_nr);
                
                output.trials{t} = [output.trials{t}; ...
                    data.trials{t}(s-1,col_stimulus_nr), ...
                    data.trials{t}(s-1, col_roi_nr), ...
                    startFrame, ...
                    func(startTime), ...
                    stopFrame, ...
                    func(stopTime), ...
                    func(duration), ...
                    mean(data.trials{t}(regionStarted:(s-1), col_overlap))];
                
                regionStarted = s;
            end

            % Fixation stopped
            if(clusterRunning && (~data.trials{t}(s, col_fixation_mask) || s == nsamples))
                clusterRunning = false;

                if(s < nsamples)
                    stopTime = mean(data.time{t}(s - [0 1]));
                else
                    stopTime = mean(data.time{t}(s));
                end

                if(clusterStarted > 1)
                    startTime = mean(data.time{t}(clusterStarted - [1 0]));
                else
                    startTime = data.time{t}(clusterStarted);
                end

                duration = stopTime - startTime;

                % Only accept fixation that last > minimum
                if(duration / 1000 / 1000 < cfg.minimumfixationduration)
                    output.trials{t}(mark:end, :) = [];
                end;                                
            end;    
        end
    end

end
