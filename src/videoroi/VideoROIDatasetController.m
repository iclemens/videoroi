classdef VideoROIDatasetController < handle
  methods(Access = public)
    function obj = VideoROIDatasetController(project, dataset)
      obj.project = project;
      obj.dataset = dataset;

      obj.playbackTimer = timer( ...
        'BusyMode', 'drop', ...
        'ExecutionMode', 'FixedSpacing', ...
        'StartDelay', round((1/30)*1000)/1000, ...
        'Period', round((1/30)*1000)/1000, ...
        'TimerFcn', @(src, tmp) obj.onTimerTick(src));
      
      obj.totalTime = 0;
      
      obj.view = VideoROIDatasetView();
      obj.view.setResolution(obj.dataset.getScreenResolution());
      obj.view.setNumberOfTrials(obj.dataset.getNumberOfTrials());
      
      obj.view.addEventListener('changeTrial', @(src, value) obj.onChangeTrial(src, value));
      obj.view.addEventListener('changeTime', @(src, value) obj.onChangeTime(src, value));
      
      obj.view.addEventListener('playPauseVideo', @(src) obj.onPlayPauseVideo(src));
      
      obj.onChangeTrial([], 1);
    end
  end
  
  properties(Access = private)
    view = [];
    
    % Project to load stimuli from
    project = [];
    
    % Dataset to display
    dataset = [];
    
    % Stimulus cache
    stimCache = cell(0, 2);
    
    currentTrial;
    playbackTimer;
    
    currentTime;
    totalTime;
    
    beginTime;
    endTime;
  end
  
  methods(Access = private)
    
    % Load/cache stimulus
    function [stim, regs] = loadStimulus(obj, stimulus)
      index = find(strcmp(obj.stimCache(:, 1), stimulus.name));
      
      if ~isempty(index)
        stim = obj.stimCache{index(1), 2};
        regs = obj.stimCache{index(1), 3};
        return;
      end
      
      [~, filename, ~] = fileparts(stimulus.name);
      stimInfo = obj.project.getInfoForStimulus(filename);
      
      if ~isstruct(stimInfo)
        warning('Invalid stimulus specified (%s)', filename);
        stim = [];
        regs = [];
        return;
      end;
      
      stimFile = fullfile(stimInfo.resourcepath, stimInfo.filename);
      
      h = waitbar(0, 'Opening stimulus...');
      
      try
        stim = VideoROIStimulus();
        stim.openStimulus(stimFile);
        close(h);
      catch e
        disp(e);
      end
      
      % Load regions of interest
      regs = VideoROIRegions(stimInfo);           
      filename = obj.project.getLatestROIFilename(stimInfo);
      
      if ~isempty(filename)
        regs.loadRegionsFromFile(filename); 
      end
      
      obj.stimCache{end + 1, 1} = stimulus.name;
      obj.stimCache{end, 2} = stim;
      obj.stimCache{end, 3} = regs;
    end


    function clearCache(obj)
      obj.stimCache = cell(0, 2);
    end
    
    
    function onChangeTrial(obj, ~, trialId)
      obj.currentTrial = trialId;
      obj.view.setCurrentTrial(obj.currentTrial);
      [samples, columns] = obj.dataset.getAnnotationsForTrial(obj.currentTrial, 'pixels');
      
      col_time = find(strcmp(columns, 'Time'));
      col_x = find(strcmp(columns, 'R POR X [px]'));
      col_y = find(strcmp(columns, 'R POR Y [px]'));
      
      obj.view.updateTrace( ...
        samples(:, col_time) /1e6, ...
        samples(:, [col_x col_y]));
            
      obj.beginTime = samples(1, col_time) / 1e6;
      obj.endTime = samples(end, col_time) / 1e6;
      
      obj.totalTime = obj.endTime - obj.beginTime;
      obj.view.setTotalTime(obj.totalTime);
      
      obj.clearCache();
      
      obj.currentTime = obj.beginTime;
      obj.view.setCurrentTime(obj.currentTime);
    end

    
    % Handle timer tick (change frame).
    % Updating occurs when the view asks for it (due to frame change).
    function onTimerTick(obj, ~)
      if obj.currentTime + 1/30 > obj.endTime
        stop(obj.playbackTimer);
        obj.view.setPlayingState(false);
      else
        obj.currentTime = obj.currentTime + 1/30;
        
        try
          obj.view.setCurrentTime(obj.currentTime);
        catch e
          rethrow e;
        end
      end
    end

    
    % Handle view's request for play or pause.
    function onPlayPauseVideo(obj, ~)
      % Start timer if it is stopped, otherwise stop timer
      if(strcmp(get(obj.playbackTimer, 'Running'), 'off'))
        % If positioned at end, start over
        if obj.currentTime + 1/30 > obj.endTime
          obj.currentTime = obj.beginTime;
          obj.view.setCurrentTime(obj.currentTime);
        end
        
        start(obj.playbackTimer);
        obj.view.setPlayingState(true);
      else
        stop(obj.playbackTimer);
        obj.view.setPlayingState(false);
      end;
    end    


    function onChangeTime(obj, ~, time)
      obj.currentTime = time;
      stimuli = obj.dataset.getStimuliAtTime(obj.currentTrial, time * 1e6);
      
      % Append data for each stimulus
      for i = 1:numel(stimuli)
        [stimulus, regions] = obj.loadStimulus(stimuli(i));
        
        if ~isempty(stimulus)
          I = stimulus.readFrame(stimuli(i).frame);
          [states, positions] = regions.getFrameInfo(stimuli(i).frame);
          stimuli(i).positions = positions(logical(states), :, :);
        else
          I = zeros(stimuli.position(3), stimuli.position(4), 3);
          I(1, :, 1) = 1;
          I(:, 1, 1) = 1;
          I(stimuli.position(3), :, 1) = 1;
          I(:, stimuli.position(4), 1) = 1;
          stimuli(i).positions = zeros(0, 1, 4);
        end
        
        stimuli(i).data = I;
      end     
      
      gaze = obj.dataset.getAnnotationsForTimeInterval(obj.currentTrial, time * 1e6, (time + 1/3) * 1e6, 'pixels');
      
      % Ask view to update scene      
      obj.view.updateScreen(stimuli, gaze);
    end
  end
end
