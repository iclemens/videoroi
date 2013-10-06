classdef VideoROIStimulusController < handle
  %
  % Controller that links VideoROIView to other functionality
  %  (Project, Stimulus, Dataset, Regions)
  %
  
  properties
    view = [];
    
    % Project to load stimuli from
    project = [];
    
    % Stimulus to display
    stimulus = [];
    
    % Dataset to display
    dataset = [];
        
    regions;
    
    currentStimulus = '';
    currentStimulusTrial = -1;
    currentDataset = '';

    playbackTimer = -1;    
    
    frameIndex;
    frameROIState;
    frameROIPosition;
    frameSceneChange;
  end
  
  methods
    function obj = VideoROIStimulusController(project, stimulus)
      obj.project = project;
      obj.stimulus = stimulus;
      
      obj.playbackTimer = timer( ...
        'BusyMode', 'drop', ...
        'ExecutionMode', 'FixedSpacing', ...
        'StartDelay', round((1/30)*1000)/1000, ...
        'Period', round((1/30)*1000)/1000, ...
        'TimerFcn', @(src, tmp) obj.onTimerTick(src));
      
      obj.view = VideoROIStimulusView();
      
      obj.regions = NaN;
      
      obj.view.addEventListener('toggleROI', @(src, index) obj.onToggleROI(src, index));
      obj.view.addEventListener('frameChange', @(src, index) obj.onFrameChange(src, index));
      obj.view.addEventListener('newROI', @(src, name, startFrame) obj.onNewROI(src, name, startFrame));
      obj.view.addEventListener('moveROI', @(src, index, position) obj.onMoveROI(src, index, position));
      obj.view.addEventListener('sceneChanged', @(src, index, value) obj.onSceneChanged(src, index, value));
      
      obj.view.addEventListener('saveROIFile', @(src) obj.onSaveROIFile(src));
      obj.view.addEventListener('importROIFile', @(src, filename) obj.onImportROIFile(src, filename));
      obj.view.addEventListener('exportROIFile', @(src, filename) obj.onExportROIFile(src, filename));
      
      obj.view.addEventListener('playPauseVideo', @(src) obj.onPlayPauseVideo(src));
    end
    
    
    function updateROIList(obj)
      numROIs = obj.regions.getNumberOfRegions;
      labels = cell(1, numROIs);
      
      for i = 1:numROIs
        labels{i} = obj.regions.getLabelForRegion(i);
      end
      
      obj.view.updateROIList(labels, obj.frameROIState);
    end
    
    
    %%%%%%%%%%%%
    % Datasets %
    %%%%%%%%%%%%
    
    
    function onChangeDataset(obj, ~, index)
      % Delete previously loaded dataset
      if(~isempty(obj.dataset))
        delete(obj.dataset);
        obj.dataset = [];
        obj.currentDataset = '';
      end;
      
      % Load new dataset
      if(index > 1)
        datasetInfo = obj.project.getInfoForDataset(index - 1);
        
        if(isstruct(datasetInfo))
          obj.currentDataset = datasetInfo.name;
          obj.dataset = VideoROIDataset(datasetInfo, obj.project.getTaskName());
        end;
      end
      
      % Redraw using saccades/fixation from loaded dataset
      try
        obj.refreshFrame();
      catch e
        % Unload dataset
        obj.onChangeDataset(0, 0);
        
        % Display error
        obj.view.displayError([e.message 10 ...
          'The selected dataset might not contain trials ' 10 ...
          'in which the selected stimulus was presented, ' 10 ...
          'or the selected task might not be valid.']);
      end
    end
    
    
    %%%%%%%%%%%
    % Stimuli %
    %%%%%%%%%%%
    
    
    function onCloseStimulus(obj, src)
      % Closes the stimulus
      
      obj.currentStimulusTrial = -1;
      obj.currentStimulus = '';
      obj.frameIndex = 1;
      
      if isa(obj.stimulus, 'VideoROIStimulus'), delete(obj.stimulus); obj.stimulus = 0; end;
      if isa(obj.regions, 'VideoROIRegions'), delete(obj.regions); obj.regions = 0; end;
      
      obj.view.setNumberOfFrames(1);
    end
    
    
    function onChangeStimulus(obj, src, index)
      % Opens a new stimulus, closing any that are already open
      
      obj.onCloseStimulus(obj);
      
      stimInfo = obj.project.getInfoForStimulus(index);
      
      if(~isstruct(stimInfo) || isempty(stimInfo.name) || isempty(stimInfo.filename))
        % Invalid video selected... bailing...
        return;
      end;
      
      stimFile = fullfile(stimInfo.resourcepath, stimInfo.filename);
      obj.currentStimulus = stimInfo.name;
      
      h = waitbar(0, 'Opening stimulus...');
      
      try
        obj.stimulus = VideoROIStimulus();
        obj.stimulus.openStimulus(stimFile);
        
        obj.regions = VideoROIRegions(stimInfo);
        
        obj.view.setNumberOfFrames(obj.stimulus.getNumberOfFrames);
        obj.frameIndex = 1;
        
        waitbar(0.8, h);
        
        % Read latest ROI if present
        filename = obj.project.getLatestROIFilename(stimInfo);
        
        if(~isempty(filename))
          obj.regions.loadRegionsFromFile(filename);
        end
        
        obj.refreshFrame();
        close(h);
      catch e
        msgbox(e.message, 'Error while opening stimulus', 'error')
        close(h);
      end
    end
    
    
    function onFrameChange(obj, ~, frame)
      obj.frameIndex = frame;
      obj.refreshFrame();
    end
    
    
    function refreshFrame(obj)
      if ~isa(obj.regions, 'VideoROIRegions'), return; end;
      
      [obj.frameROIState, obj.frameROIPosition, obj.frameSceneChange] = obj.regions.getFrameInfo(obj.frameIndex);
      I = obj.stimulus.readFrame(obj.frameIndex);
      
      % Annotate image
      if(~isempty(obj.dataset))
        ppd = obj.dataset.pixelsPerDegree();
        
        if(obj.currentStimulusTrial == -1)
          obj.currentStimulusTrial = obj.dataset.getTrialsWithStimulus(obj.currentStimulus);
          if(isempty(obj.currentStimulusTrial))
            obj.currentStimulusTrial = -1;
          end;
        end
        
        samples = obj.dataset.getAnnotationsForFrame(obj.currentStimulusTrial, obj.frameIndex);
        
        % Fixme! Should transform eye coordinates into image
        % coordinates... this only works for the movies in task 4.
        samples(:, 2) = round(samples(:, 2) / 1024 * 640);
        samples(:, 3) = round(samples(:, 3) / 768 * 480);
        
        out_of_bounds = samples(:, 2) < 1 | samples(:, 3) < 1 | samples(:, 2) > 640 | samples(:, 3) > 480;
        samples(out_of_bounds, :) = [];
        
        for s = 1:size(samples, 1)
          if(samples(s, 4))
            for j = -ceil(ppd/2):floor(ppd/2)
              I(min(640, max(1, samples(s, 3) + j)), ...
                samples(s, 2), 2) = 255;
              I(samples(s, 3), ...
                min(640, max(1, samples(s, 2) + j)), 2) = 255;
            end
          end
          
          if(samples(s, 5))
            I(samples(s, 3), samples(s, 2), 1) = 255;
          end
        end
      end
      
      
      % Swap image
      obj.view.swapImage(I);
      
      % Update rest of GUI
      obj.view.setROIInformation( ...
        obj.frameROIState, obj.frameROIPosition);
      obj.updateROIList();
      obj.view.updateROIRects(obj.frameROIState, obj.frameROIPosition);
      obj.view.setSceneChange(obj.frameSceneChange);
    end
    
    
    function onPlayPauseVideo(obj, ~)
      % Start timer if it is stopped, otherwise stop timer
      if(strcmp(get(obj.playbackTimer, 'Running'), 'off'))
        start(obj.playbackTimer);
        obj.view.setPlayingState(true);
      else
        stop(obj.playbackTimer);
        obj.view.setPlayingState(false);
      end;
    end
    
    
    function onTimerTick(obj, ~)
      if(obj.frameIndex == obj.stimulus.getNumberOfFrames)
        stop(obj.playbackTimer);
        obj.view.setPlayingState(false);
      else
        obj.view.setCurrentFrame(obj.frameIndex + 1);
      end
    end
    
    
    %%%%%%%%%%%%%%%%%%%%%%%
    % Region of interests %
    %%%%%%%%%%%%%%%%%%%%%%%
    
    
    function onNewROI(obj, ~, name, startFrame)
      if(obj.regions.getNumberOfRegions() >= 18)
        error('Unable to add ROI, only 18 regions are supported at the moment');
      end
      
      obj.regions.addRegion(name, startFrame);
      [obj.frameROIState, obj.frameROIPosition, obj.frameSceneChange] = obj.regions.getFrameInfo(obj.frameIndex);
      obj.refreshFrame();
    end
    
    
    function onToggleROI(obj, ~, index)
      % Called when the state of an ROI is toggled
      
      obj.regions.setRegionState(index, obj.frameIndex, 1 - obj.frameROIState(index));
      obj.refreshFrame();
    end
    
    
    function onSceneChanged(obj, ~, frame, value)
      obj.regions.setSceneChange(frame, value);
    end
    
    
    function onMoveROI(obj, ~, index, position)
      obj.regions.setRegionPosition(index, obj.frameIndex, position);
    end
    
    
    function onImportROIFile(obj, ~, filename)
      obj.regions.loadRegionsFromFile(filename);
      obj.refreshFrame();
    end
    
    
    function onExportROIFile(obj, ~, filename)
      obj.regions.saveRegionsToFile(filename);
    end
    
    
    function onSaveROIFile(obj, ~)
      filename = obj.project.getNextROIFilename(obj.currentStimulus);
      obj.regions.saveRegionsToFile(filename);
    end
    
  end
end