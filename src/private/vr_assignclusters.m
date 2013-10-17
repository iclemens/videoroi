function [output, regionlabels] = vr_assignclusters(cfg, data)
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
  
  regionlabels = cell(1, length(data.trials));
  for t = 1:length(data.trials)
    % First determine stimulus and frame numbers for each sample
    current_stimulus = '';
    stimulus_mask = zeros(size(data.trials{t}, 1), 1);     % Stimulus present or not
    frame_nrs = zeros(size(data.trials{t}, 1), 1);         % Which frame was shown
    
    regionlabels{t} = cell(1, length(cfg.stimuli{t}));
    
    for s = 1:length(cfg.stimuli{t})
      frame_nr = cfg.stimuli{t}(s).frame;
      if(frame_nr == 0), continue; end;
      sample_slc = cfg.stimuli{t}(s).onset:cfg.stimuli{t}(s).offset;
      stimulus_mask(sample_slc) = 1;
      frame_nrs(sample_slc) = frame_nr;
    end
    
    % Load ROIs for stimulus
    if length(cfg.stimuli{t}) < 1, continue; end;
    
    stimulus_info = get_stimulus_info(cfg.project, cfg.stimuli{t}(1).name);
    
    if ~isstruct(stimulus_info)
      fprintf('Warning: Stimulus "%s" not found in dataset.\n', cfg.stimuli{t}(1).name);
      continue;
    end
    
    region_filename = cfg.project.getLatestROIFilename(stimulus_info);
    regions = VideoROIRegions(stimulus_info);
    
    if(isempty(region_filename))
      fprintf('Warning: No ROIs defined for stimulus %s.\n', stimulus_info.name);
      continue;
    end
    
    if(~exist(region_filename, 'file'))
      fprintf('Warning: File %s does not exist', region_filename);
      continue;
    end
    
    regions.loadRegionsFromFile(region_filename);
    nregions = regions.getNumberOfRegions();
    regionlabels{t}{1} = cell(1, nregions);
    
    for r = 1:nregions
      regionlabels{t}{1}{r} = regions.getLabelForRegion(r);
    end
    
    % Remove fixations after scene change
    for s = 1:length(cfg.stimuli{t})
      frame_nr = cfg.stimuli{t}(s).frame;
      [~, ~, ischange] = regions.getFrameInfo(frame_nr + 1);
      if ~ischange, continue; end;
      
      to_remove = data.time{t} >= cfg.stimuli{t}(s).onset & ...
        data.time{t} <= cfg.stimuli{t}(s).onset + cfg.ignoreafterscenechange * 1000 * 1000;
      
      data.trials{t}(to_remove, col_fixation_mask) = 0;
    end
    
    % Then cluster and assign ROIs
    clusters = idf_cluster_mask(data.trials{t}(:, col_fixation_mask));
    output.trials{t} = nan(size(clusters, 1), length(output.labels));
    cluster_ptr = 1;
    
    for c = 1:size(clusters, 1)
      cluster_indices = clusters(c, 1):clusters(c, 2);
      
      % Compute score for every region
      scores = zeros(nregions, 1);
      total = 0;
      
      for f = frame_nrs(clusters(c, 1)):frame_nrs(clusters(c, 2))
        sel = frame_nrs == f;
        sel(1:(clusters(c, 1) - 1)) = 0;
        sel((clusters(c, 2) + 1):end) = 0;
        
        total = total + sum(sel);
        
        [roiState, roiPosition, sceneChange] = regions.getFrameInfo(f + 1);
        roiPosition(:, :, [1 3]) = roiPosition(:, :, [1 3]) ./ 640 .* 1024;
        roiPosition(:, :, [2 4]) = roiPosition(:, :, [2 4]) ./ 640 .* 1024;
        
        for r = 1:nregions
          delta_score = compute_score( ...
            data.trials{t}(sel, [col_px col_py]), ...
            squeeze(roiPosition(r, 1, :)));
          
          scores(r) = scores(r) + delta_score;
        end
      end
      
      % Find region with maximum score
      scores = scores / total;
      outside_score = 1 - sum(scores);
      [score, roi_nr] = max(scores);
      
      if(outside_score > score)
        roi_nr = 0;
        score = outside_score;
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
        1, roi_nr, ...
        frame_nrs(clusters(c, 1)), func(start_time), ...
        frame_nrs(clusters(c, 2)), func(stop_time), ...
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
