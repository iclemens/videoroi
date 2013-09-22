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
        
        currentTrial;
    end

    methods(Access = private)
        function onChangeTrial(obj, ~, trialId)
            obj.currentTrial = trialId;
            obj.view.setCurrentTrial(obj.currentTrial);
            [samples, columns] = obj.dataset.getAnnotationsForTrial(obj.currentTrial, 'pixels');

            col_time = find(strcmp(columns, 'Time'));
            col_x = find(strcmp(columns, 'R POR X [px]'));
            col_y = find(strcmp(columns, 'R POR Y [px]'));

            obj.view.updateTrace( ...
                samples(:, col_time), ...
                samples(:, [col_x col_y]));

            obj.view.setTotalTime(diff(samples([1 end], col_time)));
        end


        function onChangeTime(obj, ~, time)
            % Determine which frame / stimulus to display
            % Use the task compositor to do this?
            time
            stimuli = obj.dataset.getStimuliAtTime(obj.currentTrial, time);
            stimuli
        end
    end
end
