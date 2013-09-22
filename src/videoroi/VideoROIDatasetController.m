classdef VideoROIDatasetController < handle
    methods(Access = public)
        function obj = VideoROIDatasetController(project, dataset)
            obj.project = project;
            obj.dataset = dataset;
            
            obj.view = VideoROIDatasetView();
            obj.view.setResolution(obj.dataset.getScreenResolution());
            obj.view.setNumberOfTrials(obj.dataset.getNumberOfTrials());

            obj.view.addEventListener('changeTrial', @(src, value) obj.onChangeTrial(src, value));
            
            obj.onChangeTrial([], 1);
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

        function onChangeTrial(obj, ~, trialId)
            obj.view.setCurrentTrial(trialId);            
            [samples, columns] = obj.dataset.getAnnotationsForTrial(trialId, 'pixels');

            col_time = find(strcmp(columns, 'Time'));
            col_x = find(strcmp(columns, 'R POR X [px]'));
            col_y = find(strcmp(columns, 'R POR Y [px]'));
            
            obj.view.updateTrace( ...
                samples(:, col_time), ...
                samples(:, [col_x col_y]));
        end
    end
end
