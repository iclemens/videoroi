function events = ed_dispersion_detect_events(cfg, time, gaze)
    % Dispersion based event detection algoirhtm.
       
    % Keep track of minimum and maximum in current window
    % If either runs out of bounds, compute it again
    % If new point < min -> it is the new minimum
    % If new point > max -> it is the new maximum
    % If the 
    
    vr_initialize();        
    
    debug = 1;
    
    cfg = vr_checkconfig(cfg, 'defaults', ...
        {'minumum_fixation_duration', 0.050; ...
         'threshold', degtorad(0.8)});
    
    % Setup output structure
    events = struct();
    events.fixations = zeros(0, 2);

    % Compute frequency and window-size
    if ~isfield(cfg, 'frequency'), cfg.frequency = 1 / median(diff(time)); end;
    window_size = ceil(cfg.frequency * cfg.minimum_fixation_duration);

    if debug, fprintf('Window size: %d; frequency %.2f\n', window_size, cfg.frequency); end;

    % Apply filter to data
    gaze = ed_filter(cfg, gaze);
    
    offset = 0;
    nsamples = numel(time);
    
    while offset + window_size < nsamples
        window_limits = offset + [1 window_size];
        
        slice = gaze(window_limits(1):window_limits(2), 1:2);
        
        if dispersion(slice) < cfg.threshold
            while window_limits(2) < nsamples && dispersion(slice) < cfg.threshold
                window_limits(2) = window_limits(2) + 1;
                slice = gaze(window_limits(1):window_limits(2), 1:2);
            end
            
            offset = window_limits(2) + 1;
            events.fixations(end + 1, :) = window_limits;
        else
            offset = offset + 1;
        end
    end

    function d = dispersion(points)
        d = mean(max(points) - min(points));
    end
end
