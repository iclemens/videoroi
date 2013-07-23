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
    col_fixation_mask = strcmp(data.labels, 'fixation_mask');
    col_stimulus_nr = strcmp(data.labels, 'stimulus_nr');
    col_roi_nr = strcmp(data.labels, 'roi_nr');
    col_frame_nr = strcmp(data.labels, 'frame_nr');
    col_overlap = strcmp(data.labels, 'overlap');
    
    clusterRunning = false;
    clusterStarted = 1;    
    
    for t = 1:length(data.trials)
        nsamples = length(data.time{t});
        
        % Minimum number of samples required is 2. Probably won't
        %  result in any useful data, but the algorithm won't crash.
        if nsamples < 2, continue; end;
        
        sample_length = data.time{t}(2) - data.time{t}(1);                
        
        s = 1;
        while(s < nsamples)            
            % Skip to first cluster
            fixating = data.trials{t}(s:end, col_fixation_mask);
            stim_presented = data.trials{t}(s:end, col_stimulus_nr) > 0;
            
            delta_s = first(fixating & stim_presented);
            if(isempty(delta_s)), break; end;
            s = s + delta_s - 1;

            % Store information about cluster
            clusterStarted = s;
            regionStarted = s;
            mark = size(output.trials{t}, 1) + 1;           
            
            % While still fixating...
            while(data.trials{t}(s, col_fixation_mask))
                % Find next time region has changed or fixation is lost
                stim_presented = data.trials{t}((s+1):end, col_stimulus_nr) > 0;            
                region_changed = data.trials{t}((s+1):end, col_roi_nr) ~= data.trials{t}(regionStarted, col_roi_nr);
                not_fixating = ~data.trials{t}((s+1):end, col_fixation_mask);
                last_sample = ((s+1):nsamples) == nsamples;

                delta_s = first(stim_presented & (region_changed | not_fixating | last_sample'));

                if(isempty(delta_s)), break; end;
                s = s + delta_s;

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
                    startTime = data.time{t}(regionStarted) - sample_length / 2;
                end;
                
                if(s > 1)
                    stopTime = mean(data.time{t}(s - [0 1]));
                else
                    stopTime = data.time{t}(regionStarted) - sample_length / 2;
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

                if(s == nsamples), break; end;
                s = s + 1;
            end;
            
            % Fixation stopped
            stopTime = data.time{t}(s) - sample_length / 2;
            startTime = data.time{t}(clusterStarted) - sample_length / 2;
            duration = stopTime - startTime;

            % Only accept fixation that last > minimum
            if(duration / 1000 / 1000 < cfg.minimumfixationduration)
                output.trials{t}(mark:end, :) = [];
            end;                
        end
    end

end
