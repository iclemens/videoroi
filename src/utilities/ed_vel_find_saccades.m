function saccades = ed_vel_find_saccades(cfg, time, data) 
    % ED_VEL_FIND_SACCADES  Detects saccades using a (velocity) threshold.
    % It then tries to extend the saccade periods as long as
    % the angle is similar and the speed is decreasing.
    %
    % It returns the found saccades as a matrix containing:
    %  [start sample, stop sample]
    %
    
    vr_initialize();
    
    cfg = vr_checkconfig(cfg, 'defaults', {'minimum_saccade_duration', 0.015});
    cfg = vr_checkconfig(cfg, 'defaults', {'saccade_threshold', degtorad(45)});
    cfg = vr_checkconfig(cfg, 'defaults', {'extension_angle_threshold', 0.5 * pi});
    
    % No samples, means no saccades
    if(isempty(data) || isempty(time))
        saccades = zeros(0, 2);
        return;
    end
    
    delta_t = diff(time);
    delta_s = diff(data);
    
    dsdt = delta_s ./ delta_t(1);
    speed = sqrt(sum(dsdt .^ 2, 2));
    
    % Apply speed threshold to find saccades
    saccade_mask = ...
        ([0; speed] > cfg.saccade_threshold) | ...
        ([speed; 0] > cfg.saccade_threshold);
    
    saccades = idf_cluster_mask(saccade_mask);
    
    % Extend clusters if angle is similar and
    %  speed is decreasing.
    for c = 1:size(saccades, 1)
        running = 1;
        
        while(running && saccades(c, 1) > 1)
            previous = dsdt(saccades(c, 1) - 1, :);
            current = dsdt(saccades(c, 1), :);
            
            prevAngle = atan2(previous(2), previous(1));
            currAngle = atan2(current(2), current(1));
            
            if(previous(2) == 0 && previous(1) == 0), prevAngle = Inf; end;
            if(current(2) == 0 && current(1) == 0), currAngle = Inf; end;
            
            angle = prevAngle - currAngle;
            angle = mod(angle + pi, 2 * pi) - pi;
            
            angle_crit = abs(angle) < cfg.extension_angle_threshold;
            speed_crit = speed(saccades(c, 1) - 1) < speed(saccades(c, 1));
            
            if(angle_crit && speed_crit)
                saccades(c, 1) = saccades(c, 1) - 1;
            else
                running = 0;
            end
        end
        
        running = 1;
        while(running && saccades(c, 2) < length(saccade_mask) - 1)
            current = dsdt(saccades(c, 2) - 1, :);
            next = dsdt(saccades(c, 2), :);
            
            currAngle = atan2(current(2), current(1));
            nextAngle = atan2(next(2), next(1));
            
            if(current(2) == current(2)), currAngle = Inf; end;
            if(next(2) == next(1)), nextAngle = Inf; end;
            
            angle = nextAngle - currAngle;
            angle = mod(angle + pi, 2 * pi) - pi;
            
            angle_crit = abs(angle) < cfg.extension_angle_threshold;
            speed_crit = speed(saccades(c, 2) - 1) > speed(saccades(c, 2));
            
            if(angle_crit && speed_crit)
                saccades(c, 2) = saccades(c, 2) + 1;
            else
                running = 0;
            end
        end
    end
    
    % Remove saccades that do not meet minimum duration
    saccades( diff(time(saccades), [], 2) < cfg.minimum_saccade_duration, :) = [];
    
end
