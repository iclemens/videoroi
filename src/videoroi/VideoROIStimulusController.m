classdef VideoROIStimulusController < handle
  %
  % Controller that links VideoROIView to other functionality
  %  (Project, Stimulus, Dataset, Regions)
  %
  
  methods(Access = public)
    % Setup controller
    function obj = VideoROIStimulusController(project, stimInfo)
      obj.project = project;
      obj.stimInfo = stimInfo;
      
      obj.playbackTimer = timer( ...
        'BusyMode', 'drop', ...
        'ExecutionMode', 'FixedSpacing', ...
        'StartDelay', round((1/30)*1000)/1000, ...
        'Period', round((1/30)*1000)/1000, ...
        'TimerFcn', @(src, tmp) obj.onTimerTick(src));
            
      obj.view = VideoROIStimulusView();           

      obj.view.addEventListener('toggleROI', @(src, index) obj.onToggleROI(src, index));
      obj.view.addEventListener('frameChange', @(src, index) obj.onFrameChange(src, index));
      obj.view.addEventListener('newROI', @(src, name, startFrame) obj.onNewROI(src, name, startFrame));
      obj.view.addEventListener('moveROI', @(src, index, position) obj.onMoveROI(src, index, position));
      obj.view.addEventListener('sceneChanged', @(src, index, value) obj.onSceneChanged(src, index, value));
      
      obj.view.addEventListener('saveROIFile', @(src) obj.onSaveROIFile(src));
      obj.view.addEventListener('importROIFile', @(src, filename) obj.onImportROIFile(src, filename));
      obj.view.addEventListener('exportROIFile', @(src, filename) obj.onExportROIFile(src, filename));
      
      obj.view.addEventListener('playPauseVideo', @(src) obj.onPlayPauseVideo(src));
      
      obj.openStimulus();      
    end
  end
  
  
  properties(Access = private)
    view = [];
    
    % Project to load stimuli from
    project = [];
    
    % Stimulus and regions to display
    stimInfo = [];
    stimulus = [];
    regions = [];
    
    % Dataset to display
    dataset = [];
    datasetInfo = [];
    
    currentStimulusTrial = -1;

    playbackTimer = -1;    
    
    frameIndex = 1;
    frameROIState;
    frameROIPosition;
    frameSceneChange;
  end
  
  
  methods(Access = private)        
    % Opens the stimulus and regions at initialization.
    function openStimulus(obj)
      stimFilename = fullfile(obj.stimInfo.resourcepath, obj.stimInfo.filename);
      obj.stimulus = VideoROIStimulus();            
      obj.stimulus.openStimulus(stimFilename);

      obj.stimulus
      % Load region of interest file
      obj.regions = VideoROIRegions(obj.stimInfo);           
      filename = obj.project.getLatestROIFilename(obj.stimInfo);        
      if ~isempty(filename)
        obj.regions.loadRegionsFromFile(filename); 
      end
        
      obj.refreshFrame();
      obj.view.setNumberOfFrames(obj.stimulus.getNumberOfFrames);
    end

    
    % Open dataset for simulatenous viewing.
    % Might require transformating due to task!
    function openDataset(obj, ~, index)
      % Delete previously loaded dataset
      if ~isempty(obj.dataset)
        delete(obj.dataset);
        obj.dataset = [];
        obj.datasetInfo = [];
      end;
      
      % Load new dataset
      if index > 1
        obj.datasetInfo = obj.project.getInfoForDataset(index - 1);
        
        if isstruct(obj.datasetInfo)
          obj.dataset = VideoROIDataset(obj.datasetInfo, obj.project.getTaskName());
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
    
    
    %%%%%%%%%%%%%%%%%%%%%
    % Callback handlers %
    %%%%%%%%%%%%%%%%%%%%%
    
    
    % Handle view's request for change of frame.
    function onFrameChange(obj, ~, frame)
      obj.frameIndex = frame;
      obj.refreshFrame();
    end
    
    
    % Handle view's request for play or pause.
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
    
    
    % Handle timer tick (change frame).
    % Updating occurs when the view asks for it (due to frame change).
    function onTimerTick(obj, ~)
      if(obj.frameIndex == obj.stimulus.getNumberOfFrames)
        stop(obj.playbackTimer);
        obj.view.setPlayingState(false);
      else
        obj.view.setCurrentFrame(obj.frameIndex + 1);
      end
    end

    
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
      filename = obj.project.getNextROIFilename(obj.stimInfo);
      obj.regions.saveRegionsToFile(filename);
    end
    
    
    %%%%%%%%%%%%%%%%%%%%%%
    % Updating functions %
    %%%%%%%%%%%%%%%%%%%%%%
    

    % Update list of regions in view.
    function updateROIList(obj)
      numROIs = obj.regions.getNumberOfRegions;
      labels = cell(1, numROIs);
      
      for i = 1:numROIs
        labels{i} = obj.regions.getLabelForRegion(i);
      end
      
      obj.view.updateROIList(labels, obj.frameROIState);
    end


    % Refresh frame
    function refreshFrame(obj)
      if ~isa(obj.regions, 'VideoROIRegions'), return; end;
      
      [obj.frameROIState, obj.frameROIPosition, obj.frameSceneChange] = obj.regions.getFrameInfo(obj.frameIndex);
      I = obj.stimulus.readFrame(obj.frameIndex);
      
      % Annotate image
      if ~isempty(obj.dataset)
        ppd = obj.dataset.pixelsPerDegree();
        
        if(obj.currentStimulusTrial == -1)
          obj.currentStimulusTrial = obj.dataset.getTrialsWithStimulus(obj.stimInfo.name);
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
    
  end
  
  
  methods            
    
  end
end