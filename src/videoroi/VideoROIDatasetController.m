classdef VideoROIDatasetController < handle
    methods(Access = public)
        function obj = VideoROIDatasetController(project, dataset)
            obj.project = project;
            obj.dataset = dataset;
            
            obj.view = VideoROIDatasetView();
            obj.view.setResolution(obj.dataset.getScreenResolution());
            obj.view.setNumberOfTrials(obj.dataset.getNumberOfTrials());
                        
            obj.view.addEventListener('changeTrial', @(src, value) obj.onChangeTrial(src, value));
        end
    end

    properties(Access = private)
        view = [];

        % Project to load stimuli from
        project = [];
        
        % Dataset to display
        dataset = [];        
    end

    methods(Access = private)
        function onChangeTrial(obj, ~, value)
            obj.view.setCurrentTrial(value);
        end
    end
end
