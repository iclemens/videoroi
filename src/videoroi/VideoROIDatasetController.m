classdef VideoROIDatasetController < handle
    methods(Access = public)
        function obj = VideoROIDatasetController(project, dataset)
            obj.project = project;
            obj.dataset = dataset;
            
            resolution = obj.dataset.getScreenResolution();
            
            obj.view = VideoROIDatasetView(resolution);
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
    end
end
