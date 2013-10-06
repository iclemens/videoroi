classdef VideoROIProjectController < handle
  methods(Access = public)
    function obj = VideoROIProjectController()
      obj.view = VideoROIProjectView();
      obj.view.updateTaskList(VideoROITaskFactory.enumerateTasks());
      
      
      obj.view.addEventListener('newProject', @(src, projectDirectory) obj.onNewProject(src, projectDirectory));
      obj.view.addEventListener('openProject', @(src, projectDirectory) obj.onOpenProject(src, projectDirectory));
      obj.view.addEventListener('closeProject', @(src) obj.onCloseProject(src));
      
      obj.view.addEventListener('addStimulus', @(src, filename) obj.onAddStimulus(src, filename));
      obj.view.addEventListener('addDataset', @(src, filename) obj.onAddDataset(src, filename));
      
      obj.view.addEventListener('openStimulus', @(src, index) obj.onOpenStimulus(src, index));
      obj.view.addEventListener('openDataset', @(src, index) obj.onOpenDataset(src, index));
      
      obj.view.addEventListener('setTask', @(src, taskName) obj.onSetTask(src, taskName));
      obj.view.addEventListener('toggleOverlap', @(src) obj.onToggleOverlap(src));
      
      obj.view.addEventListener('performAnalysis', @(src, filename) obj.onPerformAnalysis(src, filename));
    end
    
    
    %%%%%%%%%%%%%%%%%%%%%%
    % PROJECT MANAGEMENT %
    %%%%%%%%%%%%%%%%%%%%%%
    
    
    function onNewProject(obj, ~, projectDirectory)
      % Creates a new project.
      
      % Close project if one was open
      if isa(obj.project, 'VideoROIProject')
        obj.onCloseProject(obj);
      end
      
      % Try to create a new project
      try
        obj.project = VideoROIProject(projectDirectory);
        obj.view.updateOverlapState(obj.project.getOverlapState());
      catch err
        obj.view.displayError(err.message);
      end
    end
    
    
    % Open a project.
    function onOpenProject(obj, ~, projectDirectory)      
      % Close project if one is open
      if isa(obj.project, 'VideoROIProject')
        obj.onCloseProject(obj);
      end
      
      % Try to open the project
      try
        obj.project = VideoROIProject(projectDirectory);
        obj.view.updateOverlapState(obj.project.getOverlapState());
        obj.updateStimulusList();
        obj.updateDatasetList();
      catch err
        obj.view.displayError(err.message);
      end
    end
    
    
    % Close the currently open project.
    function onCloseProject(obj, ~)
      obj.project = [];
      obj.view.updateStimulusList({});
      obj.view.updateDatasetList({});
    end
    
    
    % Toggles whether ROIs may overlap.
    function onToggleOverlap(obj, ~)
      if ~isa(obj.project, 'VideoROIProject')
        obj.view.displayError('Cannot set task, project not open');
        return;
      end
      
      state = 1 - obj.project.getOverlapState();
      obj.project.setOverlapState(state);
      obj.view.updateOverlapState(obj.project.getOverlapState());
    end
    
    
    % Sets the task used by the project
    function onSetTask(obj, ~, taskName)
      if ~isa(obj.project, 'VideoROIProject')
        obj.view.displayError('Cannot set task, project not open');
        return;
      end
      
      obj.project.setTaskName(taskName);
      
      % Fixme: should inform open datasets they should reload.
    end
  end
  
  
  properties(Access = private)
    % Project view
    view = [];
    
    % List of open stimuli and dataset (controllers)
    openStimuli = cell(1, 2);
    openDatasets = cell(1, 2);
    
    % Overlap state variable
    overlapState = 1;
    
    % Currently loaded project
    project = [];
  end
  
  
  methods(Access = private)
    % Add dataset to project.
    function onAddDataset(obj, ~, filename)      
      if(~isempty(obj.project))
        try
          obj.project.addDataset(filename);
          obj.updateDatasetList();
        catch err
          obj.view.displayError(err.message);
        end
      else
        error('VideoROI:NoProjectLoaded', 'No project loaded, unable to add dataset');
      end
    end
    
    
    % Add stimulus to project.
    function onAddStimulus(obj, ~, filename)      
      if(~isempty(obj.project))
        try
          obj.project.addStimulus(filename);
          obj.updateStimulusList();
        catch err
          obj.view.displayError(err.message);
        end
      else
        error('VideoROI:NoProjectLoaded', 'No project loaded, unable to add stimulus');
      end
    end
    

    % Open eye-trace view.    
    function onOpenDataset(obj, ~, index)      
      datasetInfo = obj.project.getInfoForDataset(index);
      
      if ~isstruct(datasetInfo)
        obj.view.displayError('Selected dataset is corrupt.');
        return;
      end
      
      dataset = VideoROIDataset(datasetInfo, obj.project.getTaskName());
      VideoROIDatasetController(obj.project, dataset);
    end
    
    
    % Open stimulus and region view.
    function onOpenStimulus(obj, ~, index)      
      stimInfo = obj.project.getInfoForStimulus(index);
      
      if ~isstruct(stimInfo)
        obj.view.displayError('Selected stimulis is corrupt.');
        return;
      end
      
      stimulus = VideoROIStimulus();
      stimulus.openStimulus(stimInfo.resourcepath);
      VideoROIStimulusController(obj.project, stimulus);
    end
    
    
    % Update list of datasets.
    function updateDatasetList(obj)      
      numDatasets = obj.project.getNumberOfDatasets;
      labels = cell(1, numDatasets);
      
      for i = 1:numDatasets
        datasetInfo = obj.project.getInfoForDataset(i);
        labels{i} = datasetInfo.name;
      end
      
      obj.view.updateDatasetList(labels);
    end
    
    
    % Update list of stimuli.
    function updateStimulusList(obj)
      numStimuli = obj.project.getNumberOfStimuli;
      labels = cell(1, numStimuli);
      
      for i = 1:numStimuli
        stimInfo = obj.project.getInfoForStimulus(i);
        labels{i} = stimInfo.name;
      end
      
      obj.view.updateStimulusList(labels);
    end
  end
end
