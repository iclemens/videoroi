function [output, uniqueRegions] = vr_assignclusters(cfg, data)
  % VR_ASSIGNCLUSTER  Assign ROIs to fixation clusters.
  %  FIXME: Currently only works for movies.
  %
  
  vr_initialize();
  
  % Check configuration
  vr_checkconfig(cfg, 'required', 'project');
  vr_checkconfig(cfg, 'required', 'stimuli');
  cfg = vr_checkconfig(cfg, 'defaults', {'ignoreafterscenechange', 0.15});
  cfg = vr_checkconfig(cfg, 'defaults', {'minimumfixationduration', 0.10});
  cfg = vr_checkconfig(cfg, 'defaults', {'units', 'ms'});
  
  % Select function to use for unit conversion
  func = @(x) x;
  if(strcmp(cfg.units, 'us'))
    func = @(x) round(x);
  elseif(strcmp(cfg.units, 'ms'))
    func = @(x) round(x / 1000.0);
  elseif(strcmp(cfg.units, 's'))
    func = @(x) round(x / 1000.0) / 1000.0;
  end
  
  % Prepare output structure
  output = struct();
  output.cfg = cfg;
  if(isfield(data, 'cfg')), output.cfg.previous = data.cfg; end;
  output.labels = {'stimulus_nr', 'roi_nr', 'f_fix_start', 't_fix_start', 'f_fix_stop', 't_fix_stop', 'fix_duration', 'overlap'};
  output.trials = cell(1, length(data.trials));
  
  % Find columns of interest in input data
  col_px = find(strcmp(data.labels, 'px'));
  col_py = find(strcmp(data.labels, 'py'));
  col_fixation_mask = strcmp(data.labels, 'fixation_mask');
  
  uniqueRegions = cell(1, length(data.trials));
  
  for t = 1:length(data.trials)
    uniqueRegions{t} = cell(1, 0);
    
    % Load regions of interest for all stimuli    
    for s = 1:numel(cfg.stimuli{t})
      stimulus_info = get_stimulus_info(cfg.project, cfg.stimuli{t}(s).name);

      % Initialize empty values in case stimulus could not be found/loaded
      cfg.stimuli{t}(s).regionState = [];
      cfg.stimuli{t}(s).regionPositions = zeros(0, 1, 4);
      cfg.stimuli{t}(s).sceneChange = 0;
      cfg.stimuli{t}(s).regionLabels = {};
      
      if ~isstruct(stimulus_info)
        fprintf('Warning: Stimulus "%s" not found in dataset.\n', cfg.stimuli{t}(s).name);
        continue;
      end

      region_filename = cfg.project.getLatestROIFilename(stimulus_info);
      regions = VideoROIRegions(stimulus_info);

      if isempty(region_filename)
        fprintf('Warning: No ROIs defined for stimulus %s.\n', stimulus_info.name);
        continue;
      end

      if ~exist(region_filename, 'file')
        fprintf('Warning: File %s does not exist', region_filename);
        continue;
      end

      regions.loadRegionsFromFile(region_filename);
      nregions = regions.getNumberOfRegions();

      [roiState, roiPosition, sceneChange] = regions.getFrameInfo(cfg.stimuli{t}(s).frame);      
      
      cfg.stimuli{t}(s).regionLabels = cell(1, nregions);
      for r = 1:nregions
        cfg.stimuli{t}(s).regionLabels{r} = regions.getLabelForRegion(r);

        if ~any(strcmp(uniqueRegions{t}, cfg.stimuli{t}(s).regionLabels{r}))
          uniqueRegions{t}{end + 1} = cfg.stimuli{t}(s).regionLabels{r};
        end
      end
      
      cfg.stimuli{t}(s).regionState = roiState;
      cfg.stimuli{t}(s).sceneChange = sceneChange;
      cfg.stimuli{t}(s).regionPositions = roiPosition;
      
      % Convert region positions into screen coordinates
      for r = 1:nregions
        cfg.stimuli{t}(s).regionPositions(r, 1, 1) = cfg.stimuli{t}(s).regionPositions(r, 1, 1) .* ...
          cfg.stimuli{t}(s).position(3) / stimulus_info.width + cfg.stimuli{t}(s).position(1);
        cfg.stimuli{t}(s).regionPositions(r, 1, 3) = cfg.stimuli{t}(s).regionPositions(r, 1, 3) .* ...
          cfg.stimuli{t}(s).position(3) / stimulus_info.width;
        
        cfg.stimuli{t}(s).regionPositions(r, 1, 2) = cfg.stimuli{t}(s).regionPositions(r, 1, 2) .* ...
          cfg.stimuli{t}(s).position(4) / stimulus_info.height + cfg.stimuli{t}(s).position(2);
        cfg.stimuli{t}(s).regionPositions(r, 1, 4) = cfg.stimuli{t}(s).regionPositions(r, 1, 4) .* ...        
          cfg.stimuli{t}(s).position(4) / stimulus_info.height;
      end      
    end

    nregions = numel(uniqueRegions{t});
    
    
    % Remove fixations after scene change
    for s = 1:length(cfg.stimuli{t})
      if ~cfg.stimuli{t}(s).sceneChange, continue; end;
      
      to_remove = data.time{t} >= cfg.stimuli{t}(s).onset & ...
        data.time{t} <= cfg.stimuli{t}(s).onset + cfg.ignoreafterscenechange * 1000 * 1000;
      
      data.trials{t}(to_remove, col_fixation_mask) = 0;
    end


    % Then cluster and assign ROIs
    clusters = idf_cluster_mask(data.trials{t}(:, col_fixation_mask));
    output.trials{t} = nan(size(clusters, 1), length(output.labels));
    cluster_ptr = 1;
    
    for c = 1:size(clusters, 1)
      %cluster_indices = clusters(c, 1):clusters(c, 2);
      
      % Compute score for every region
      scores = zeros(numel(cfg.stimuli{t}), nregions);
      total = clusters(c, 2) - clusters(c, 1) + 1;
      
      for s = 1:numel(cfg.stimuli{t})
        % Determine samples valid for this stimulus               
        sel = max(cfg.stimuli{t}(s).onset, clusters(c, 1)):min(cfg.stimuli{t}(s).offset, clusters(c, 2));

        % Don't bother if it is empty (outside of range)
        if isempty(sel), continue; end;
        
        for r = 1:numel(cfg.stimuli{t}(s).regionLabels)
          % Skip invisible ID
          if ~cfg.stimuli{t}(s).regionState(r), continue; end;
          
          % Find global region id
          ur_id = strcmp(uniqueRegions{t}, cfg.stimuli{t}(s).regionLabels{r});
          
          delta_score = compute_score( ...
            data.trials{t}(sel, [col_px, col_py]), ...
            squeeze(cfg.stimuli{t}(s).regionPositions(r, :, :)));
          scores(s, ur_id) = scores(s, ur_id) + delta_score;
        end
      end

      if isempty(scores)
        roi_nr = 0;
        stim_nr = 0;
        score = NaN;
      else      
        score_by_region = sum(scores) / total;
      
        % Find region with maximum score        
        outside_score = 1 - sum(score_by_region);
        [score, roi_nr] = max(score_by_region);
                        
        if(outside_score > score)
          stim_nr = 0;
          roi_nr = 0;
          score = outside_score;
        else
          [~, stim_nr] = max(scores(:, roi_nr));
        end
      end
      
      % Prepare information about this cluster
      if(clusters(c, 1) > 1)
        start_time = mean(data.time{t}(clusters(c, 1) - [0 1]));
      else
        start_time = data.time{t}(clusters(c, 1));
      end;
      
      if(clusters(c, 2) > 1)
        stop_time = mean(data.time{t}(clusters(c, 2) - [0 1]));
      else
        stop_time = data.time{t}(clusters(c, 2));
      end;

      cluster_info = [ ...
        stim_nr, roi_nr, ...
        -1, func(start_time), ...
        -1, func(stop_time), ...
        func(stop_time - start_time), score];
      
      if (stop_time - start_time) >= cfg.minimumfixationduration * 1000.0 * 1000.0        
        output.trials{t}(cluster_ptr, :) = cluster_info;        
        cluster_ptr = cluster_ptr + 1;
      end;
    end
    
    % Remove excess rows
    output.trials{t}(cluster_ptr:end, :) = [];
  end
  
  
  function score = compute_score(fixation, roi)
    % Compute region corners
    xr = roi(1) + [0 roi(3)];
    yr = roi(2) + [0 roi(4)];
    
    x = fixation(:, 1) >= xr(1) & fixation(:, 1) <= xr(2);
    y = fixation(:, 2) >= yr(1) & fixation(:, 2) <= yr(2);
    
    score = sum(x & y);
  end
  
  
  function stimulus_info = get_stimulus_info(project, name)
    % GET_STIMULUS_INFO  Find and return information about the
    % stimulus with name [name] in the specified project.
    
    stimulus_info = project.getInfoForStimulus(name);
    
    if(isnan(stimulus_info))
      dots = find(name == '.');
      stimulus_info = project.getInfoForStimulus(name(1:dots(end) - 1));
    end
  end
end
