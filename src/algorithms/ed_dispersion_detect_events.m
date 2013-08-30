function events = ed_dfn_detect_events(cfg, time, gaze)
    % Dispersion based event detection algoirhtm.
    
    vr_initialize();
    
    debug = 1;
    
    cfg = vr_checkconfig(cfg, 'defaults', ...
        {'minumum_fixation_duration', 0.050; ...
         'threshold', 0.0015});
    
    % Setup output structure
    events = struct();
    events.fixations = zeros(0, 2);

    frequency = 1 / (time(2) - time(1));
    frequency = 1 / median(diff(time));
    window_size = ceil(frequency * cfg.minimum_fixation_duration);
    offset = 0;

    if debug, fprintf('Window size: %d; frequency %.2f\n', window_size, frequency); end;

    while offset + window_size < numel(time)
        window_limits = offset + [1 window_size];
        
        slice = gaze(window_limits(1):window_limits(2), end);
        
        if dispersion(slice) < cfg.threshold
            while window_limits(2) < size(time, 1) && dispersion(slice) < cfg.threshold
                window_limits(2) = window_limits(2) + 1;
                slice = gaze(window_limits(1):window_limits(2), end);
            end
            
            offset = window_limits(2);
            window_limits
            events.fixations(end + 1, :) = window_limits;
        else
            offset = offset + 1;
        end
    end

    function d = dispersion(points)
        d = mean(max(points) - min(points));
    end
end
