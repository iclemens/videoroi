classdef VideoROIDatasetController < handle
  methods(Access = public)
    function obj = VideoROIDatasetController(project, dataset)
      obj.project = project;
      obj.dataset = dataset;
      
      obj.view = VideoROIDatasetView();
      obj.view.setResolution(obj.dataset.getScreenResolution());
      obj.view.setNumberOfTrials(obj.dataset.getNumberOfTrials());
      
      obj.view.addEventListener('changeTrial', @(src, value) obj.onChangeTrial(src, value));
      obj.view.addEventListener('changeTime', @(src, value) obj.onChangeTime(src, value));
      
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
  end
  
  methods(Access = private)
    
    % Load/cache stimulus
    function stim = loadStimulus(obj, stimulus)
      index = find(strcmp({obj.stimCache{:, 1}}, stimulus.name));
      
      if ~isempty(index)
        stim = obj.stimCache{index(1), 2};
        return;
      end
      
      [~, filename, ~] = fileparts(stimulus.name);
      stimInfo = obj.project.getInfoForStimulus(filename);
      
      if ~isstruct(stimInfo)
        warning('Invalid stimulus specified');
        stim = [];
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
      
      obj.stimCache{end + 1, 1} = stimulus.name;
      obj.stimCache{end, 2} = stim;
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
      
      obj.view.setTotalTime(diff(samples([1 end], col_time)) / 1e6);
      obj.clearCache();
    end
    
    
    function onChangeTime(obj, ~, time)
      stimuli = obj.dataset.getStimuliAtTime(obj.currentTrial, time * 1e6);
      
      % Append data for each stimulus
      for i = 1:numel(stimuli)
        stimulus = obj.loadStimulus(stimuli(i));
        
        if ~isempty(stimulus)
          I = stimulus.readFrame(stimuli(i).frame);
        else
          I = zeros(stimuli.position(3), stimuli.position(4), 3);
          I(1, :, 1) = 1;
          I(:, 1, 1) = 1;
          I(stimuli.position(3), :, 1) = 1;
          I(:, stimuli.position(4), 1) = 1;
        end
        
        stimuli(i).data = I;
      end
      
      % Ask view to update scene      
      obj.view.updateScreen(stimuli);
    end
  end
end
