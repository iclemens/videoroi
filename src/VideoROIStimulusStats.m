function VideoROIStimulusStats(cfg)
% VIDEOROISTIMULUSSTATS  Computes statistics for each stimulus in a project.
  
  if isfield(cfg, 'project') && isfield(cfg, 'projectdirectory')
    error('VideoROIAnalysis:cfgError', 'Configuration cannot both contain project and projectDirectory.');
  end

  if isfield(cfg, 'project')
    cfg = vr_checkconfig(cfg, 'validate', {'project', @(v) isa(v, 'VideoROIProject')});
    cfg.projectdirectory = '';
  else
    cfg = vr_checkconfig(cfg, 'defaults', {'projectdirectory', @(x) uigetdir('', 'Open project directory')});
    cfg = vr_checkconfig(cfg, 'validate', {'projectdirectory', @(v) ~isempty(v) && ischar(v) && exist(v, 'dir') == 7});
  end

  cfg = vr_checkconfig(cfg, 'defaults', {'outputfile', fullfile(cfg.projectdirectory, 'stim_stats.csv')});   


  % Open project and output file
  if isfield(cfg, 'project')
    project = cfg.project;
  else
    project = VideoROIProject(cfg.projectdirectory);
  end

  taskName = project.getTaskName();
  task = VideoROITaskFactory.obtainTaskInstance(taskName);

  [outputFile, message] = fopen(cfg.outputfile, 'w');
  if(outputFile == -1), error(['could not open output file: ' message]); end

  
  numStimuli = project.getNumberOfStimuli();
  
  fprintf(outputFile, 'Stimulus, Region, RegionAreaPx, AllRegionsAreaPx, ScreenAreaPx\n');
  
  for s = 1:numStimuli
    stimInfo = project.getInfoForStimulus(s);
    roiFile = project.getLatestROIFilename(stimInfo);
    
    regions = VideoROIRegions(stimInfo);
    regions.loadRegionsFromFile(roiFile);
    
    numFrames = stimInfo.frames;    
    numRegions = regions.getNumberOfRegions();
    
    totalArea = zeros(numRegions, 1);
    screenArea = 0;
    
    for f = 1:numFrames
      [states, positions] = regions.getFrameInfo(f);
      
      % roi, 1, pos
      % X Y W H
      
      area = positions(:, :, 3) .* positions(:, :, 4) .* states;      
      totalArea = totalArea + area;
      screenArea = screenArea + (1024 * 768);
    end

    for r = 1:numRegions
      label = regions.getLabelForRegion(r);      
      fprintf(outputFile, '"%s", "%s", %d, %d, %d\n', task.getTrialDescription(stimInfo), label, totalArea(r), sum(totalArea), screenArea);
    end
    
  end
  