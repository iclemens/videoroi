function vr_fixationstofile(cfg, data)
% VR_FIXATIONSTOFILE  Writes a file containing fixation intervals.

    % Select function to use for unit conversion
    func = @(x) x;
    if(strcmp(cfg.units, 'us'))
        func = @(x) round(x);
    elseif(strcmp(cfg.units, 'ms'))
        func = @(x) round(x / 1000.0);
    elseif(strcmp(cfg.units, 's'))
        func = @(x) round(x / 1000.0) / 1000.0;
    end

    clusterRunning = false;
    clusterStarted = 1;

    % Find relevant columns
    col_fixation_mask = strcmp(data.labels, 'fixation_mask');   %2
    col_stimulus_nr = strcmp(data.labels, 'stimulus_nr');       %3
    col_roi_nr = strcmp(data.labels, 'roi_nr');             %4
    col_frame_nr = strcmp(data.labels, 'frame_nr');         %5
    col_overlap = strcmp(data.labels, 'overlap');

    for t = 1:length(data.trials)
        nsamples = length(data.time{t});
        for s = 1:nsamples            
            % Fixation cluster started
            if(~clusterRunning && data.trials{t}(s, col_fixation_mask))
                clusterRunning = true;
                clusterStarted = s;
                regionStarted = s;
                buffer = {};
            end

            % Region of interest has changed
            if(clusterRunning && s > 1 && data.trials{t}(s - 1, col_stimulus_nr) > 0 && ...
                    ( ...                        
                        (data.trials{t}(s, col_roi_nr) ~= data.trials{t}(regionStarted, col_roi_nr)) || ... % Region has changed
                        ~(data.trials{t}(s, col_fixation_mask)) || ...     % Not fixating anymore
                        s == nsamples ...   % Last sample
                    ))

                if(data.trials{t}(s-1, col_roi_nr) == 0)
                    regionLabel = 'OutsideRegions';
                else
                    regionLabel = cfg.regionlabels{t}{data.trials{t}(s - 1, col_stimulus_nr)}{data.trials{t}(s - 1, col_roi_nr)};
                end

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

                buffer{end + 1} = sprintf('"%s", "%s", "%s", %d, %d, %d, %d, %d, %d, %.2f\r\n', ...
                    cfg.datasetname, ...
                    cfg.stimuli{t}( data.trials{t}(s-1,col_stimulus_nr) ).name, ...
                    regionLabel, ...
                    data.trials{t}(s-1, col_roi_nr), ...
                    startFrame, ...
                    func(startTime), ...
                    stopFrame, ...
                    func(stopTime), ...
                    func(duration), ...
                    mean(data.trials{t}(regionStarted:(s-1), col_overlap)) ...
                    );

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

                % Only except fixation that last > minimum
                if(duration / 1000 / 1000 >= cfg.minimumfixationduration)
                    for b = 1:length(buffer)
                        fprintf(cfg.outputfile, buffer{b});
                    end
                    buffer = {};
                end;                                
            end;    
        end
    end
end
