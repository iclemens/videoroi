function events = ed_velocity_detect_events(cfg, time, data)
%
% Detects events based on a velocity criterion.
%
%  cfg - Configuration structure
%  time - Time (in seconds)
%  data - ...
%
  
    events = struct();

    if ~isfield(cfg, 'frequency'), cfg.frequency = 1 / median(diff(time)); end;
    if ~vr_checkfrequency(cfg.frequency), error('Invalid frequency'); end;
    
    data = ed_filter(cfg, data);

    events.saccades = ed_vel_find_saccades(cfg, time, data);
    saccade_mask = idf_mask_cluster(events.saccades, length(time));
    
    % Fixations are not saccades
    fixation_mask = ~saccade_mask;
    events.fixations = idf_cluster_mask(fixation_mask);
    
    if(~isempty(time) && ~isempty(data))
        % Compute time between samples
        sample_time = time(2) - time(1);
        
        % Remove fixation which do not meet minimum duration
        fixation_time = sample_time * diff(events.fixations, [], 2);        
        events.fixations(fixation_time < cfg.minimum_fixation_duration, :) = [];                
    end
end
