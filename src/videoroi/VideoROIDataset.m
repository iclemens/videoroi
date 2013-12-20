classdef VideoROIDataset < handle
%
% Loads a dataset and performs rudimentary analysis (e.g. saccade detection
%  and conversion into angles).
%

    properties(Access = private)
        datasetInfo;

        % Screen distance, dimensions and resolution
        screen;

        taskName = '';
        methodName = '';
        
        % Data from eye-tracker
        header;
        data;
    end


    methods(Access = public)


        function obj = VideoROIDataset(datasetInfo, taskName)
            obj.taskName = taskName;
            obj.datasetInfo = datasetInfo;
            obj.loadCache();

            obj.methodName = 'velocity';
            
            scr = [];
            scr.distance = 500;
            scr.resolution = [1024 768];
            scr.dimensions = [403 305];

            obj.defineScreen(scr);
        end
        

        %
        % Returns the number of pixels per degree (for centre of screen).
        %
        function ppd = getPixelsPerDegree(obj)
            lengthperdeg = tan(degtorad(1)) * obj.screen.distance;
            ppd = lengthperdeg / obj.screen.dimensions(1) * obj.screen.resolution(1);
        end
        
        
        %
        % Returns screen resolution.
        %
        function resolution = getScreenResolution(obj)
            resolution = obj.screen.resolution;
        end
        
        
        %
        % Set screen properties for calibration
        %
        function defineScreen(obj, screen)
            obj.screen = screen;
            obj.updateGazeCoordinates();
            obj.annotateTrace();
        end


        %
        % Return number of trials
        %
        function count = getNumberOfTrials(obj)
            count = length(obj.data);
        end


        %
        % List the trials in which a given stimulus is presented
        %
        function list = getTrialsWithStimulus(obj, stimulusName)            
            list = [];
            
            % Dataset messages have not been processed,
            % either no task has been selected or the task is
            % invalid.
            if ~isfield(obj.data, 'stimulus')
                err = MException('VideoROI:NoStimuli', ...
                    'Cannot get trials for stimulus because no stimuli have been defined.');
                throw(err);
            end
            
            for t = 1:length(obj.data)
                for s = 1:length(obj.data(t).stimulus)                    
                    [~, name, ~] = fileparts(obj.data(t).stimulus(s).name);
                    if strcmpi(name, stimulusName)
                        list(end + 1) = t;
                        break;
                    end                    
                end
            end            
        end
        
        
        % Return all stimuli for a given trial
        function stimuli = getStimuliForTrial(obj, trialId)
            stimuli = obj.data(trialId).stimulus;
        end       


        % Returns a textual description for a given trial
        % If no task is set, this function will fail.
        function descr = getDescriptionForTrial(obj, trialId)
          task = VideoROITaskFactory.obtainTaskInstance(obj.taskName);
          descr = task.getTrialDescription(obj.data(trialId).stimulus);
        end


        %
        % Returns the stimuli being presented at a given point in time.
        %
        function stimuli = getStimuliAtTime(obj, trialId, time)
            col_time = strcmp(obj.header.Columns, 'Time');            
            [~, sample] = min(abs(obj.data(trialId).samples(:, col_time) - time));
            
            stimuli = obj.data(trialId).stimulus( ...
                [obj.data(trialId).stimulus.onset] <= sample & ...
                [obj.data(trialId).stimulus.offset] >= sample);
        end
        
        
        function [samples, columns] = getAnnotationsForTrial(obj, trialId, units)
            if nargin < 3
                [samples, columns] = obj.getAnnotationsForInterval(trialId, -Inf, Inf);
            else
                [samples, columns] = obj.getAnnotationsForInterval(trialId, -Inf, Inf, units);
            end
        end
                       
        
        function [samples, columns] = getAnnotationsForFrame(obj, trialId, frameNr)
            sel = cellfun(@(x) ~isempty(x) && x == frameNr, {obj.data(trialId).stimulus.frame});
            
            if isempty(sel) || isempty(obj.data(trialId).stimulus(sel))
                disp('Warning: Unable to get samples for current frame, not contained in dataset.');
                [samples, columns] = obj.getAnnotationsForInterval(trialId, 0, 0);
                return
            end

            [samples, columns] = obj.getAnnotationsForInterval(trialId, obj.data(trialId).stimulus(sel).onset, obj.data(trialId).stimulus(sel).offset);
        end
        
        
        function [samples, columns] = getAnnotationsForTimeInterval(obj, trialId, from, to, units)
          if nargin < 5, units = 'pixels'; end;
          
          col = idf_find_columns({'Time'}, obj.header);

          [~, first] = min(abs(obj.data(trialId).samples(:, col) - from));
          [~, last] = min(abs(obj.data(trialId).samples(:, col) - to));
          
          [samples, columns] = obj.getAnnotationsForInterval(trialId, first, last, units);
        end

        
        function [samples, columns] = getAnnotationsForInterval(obj, trialId, first, last, units)
            % Returns fixation and saccade annotations together with
            % eye position information for a specific interval.
            % Unit specifies the unit in which to express the eye
            % movement information, currently only 'pixels' and 'radians'
            % are supported.

            % The default unit is pixels
            if nargin < 5, units = 'pixels'; end;
            
            dta = obj.data(trialId);
            
            if strcmp(units, 'pixels')
                columns = {'Time', 'R POR X [px]', 'R POR Y [px]'};
            elseif strcmp(units, 'radians')
                columns = {'Time', 'R Gaze X [rad]', 'R Gaze Y [rad]'};
            else
                error('VideoROI:Dataset:invalidUnit', 'Only pixels and radians are supported');
            end
            
            cols = idf_find_columns(columns, obj.header);
            
            columns{end + 1} = 'Fixation mask';
            columns{end + 1} = 'Saccade mask';
            
            % Handle infinity (i.e. from beginning or until end)
            if(isinf(first)) || (first < 1), first = 1; end;
            if(isinf(last)), last = size(dta.samples, 1); end;
            
            intervalMask = first:last;
            
            samples = [dta.samples(intervalMask, cols), dta.fixation_mask(intervalMask), dta.saccade_mask(intervalMask)];
            
            % There are no samples within the interval, but we'll make sure
            % that the right amount of columns will be returned.
            if(isempty(samples))
                samples = zeros(0, length(columns));
            end
        end
        
    end
    

    methods(Access = private)
        
        %%%%%%%%%
        % Cache %
        %%%%%%%%%


        function generateCache(obj)
            % Regenerate cache
            
            cacheFile = fullfile(obj.datasetInfo.resourcepath, 'cache.dat');
            sourceFile = fullfile(obj.datasetInfo.resourcepath, obj.datasetInfo.filename);
                
            [s, m, header] = read_idf(sourceFile);
            data = idf_split_trials(s, m);
            
            % Add empty stimulus information
            for t_id = 1:length(data)
                data(t_id).stimulus = struct('name', {}, 'frame', {}, ...
                    'onset', {}, 'offset', {}, 'position', {});
            end;            
            
            % Perform task specific message parsing
            if(~isempty(obj.taskName))
                task = VideoROITaskFactory.obtainTaskInstance(obj.taskName);
                data = task.parseStimulusMsgs(data);
            end
            
            taskName = obj.taskName;            
            version = 2;

            save(cacheFile, 'version', 'header', 'data', 'taskName');
        end

        
        function loadCache(obj)
            % Load raw data from cache
            
            cacheFile = fullfile(obj.datasetInfo.resourcepath, 'cache.dat');
            
            % Generate cache if it does not already exist
            if(~exist(cacheFile, 'file'))
                obj.generateCache();
            end

            % Attempt to load cache file
            tmp = load(cacheFile, '-mat');
            
            % If the cache-version is not correct, regenerate
            if(tmp.version ~= 2)
                obj.generateCache();
                tmp = load(cacheFile, '-mat');
            end

            % Task has changed
            if(~isfield(tmp, 'taskName') || ~strcmp(tmp.taskName, obj.taskName))
                obj.generateCache();
                tmp = load(cacheFile, '-mat');
            end
            
            % Store data in a property            
            obj.header = tmp.header;
            obj.data = tmp.data;
        end
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Coordinate transformations %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        
        function updateGazeCoordinates(obj)
            % Update gaze coordinates given screen information

            if(~isstruct(obj.data)), return; end;
            if(~isstruct(obj.screen)), return; end;

            cfg = [];
            cfg.src = {'R POR X [px]', 'R POR Y [px]'};
            cfg.dest = {'R Gaze X [rad]', 'R Gaze Y [rad]'};

            cfg.procfcn = @(cfg, src) [ ...
                atan2(obj.screen.distance, (src(:, 1) ./ obj.screen.resolution(1) - 0.5) .* obj.screen.dimensions(1)) - 0.5 * pi, ...
                atan2(obj.screen.distance, (src(:, 2) ./ obj.screen.resolution(2) - 0.5) .* obj.screen.dimensions(2)) - 0.5 * pi];

            [obj.data, obj.header] = idf_transform_data(cfg, obj.data, obj.header);
        end
        
        
        %%%%%%%%%%%%%%
        % Annotation %
        %%%%%%%%%%%%%%
                       
        
        function annotateTrace(obj)
            % Detect saccades and fixations

            % Configuration of event detection algorithm
            edcfg = struct();
            edcfg.saccade_threshold = degtorad(45);
            edcfg.minimum_fixation_duration = 0.1; %100ms
            edcfg.extension_angle_threshold = 0.5 * pi;
            
            col_time = idf_find_columns({'Time'}, obj.header);
            col_gaze = idf_find_columns({'R Gaze X [rad]', 'R Gaze Y [rad]'}, obj.header);

            % Determine which columns to use
            if(isempty(col_time))
                error('VideoROI:DatasetInvalid', ...
                    'Selected dataset does not contain timestamp.');
            end
            
            if(isempty(col_gaze))
                error('VideoROI:DatasetInvalid', ...
                    'Selected dataset does not contain gaze information.');
            end
            
            detectFunc = str2func(['ed_' obj.methodName '_detect_events']);
            
            for t = 1:length(obj.data)
                % Raise an error when the dataset is empty                
                if(size(obj.data(t).samples, 2) == 0)
                    error('VideoROI:InvalidSize', ...
                        ['Matrix for trail ' num2str(t) ' does not have enough columns.']);
                end
                
                time = obj.data(t).samples(:, col_time) * 1e-6;
                gaze = obj.data(t).samples(:, col_gaze);

                % Event detection might fail when there are not enough samples.
                try
                  events = detectFunc(edcfg, time, gaze);
                catch
                  % Only show warning if the trial contains more than 50 samples
                  if numel(time) > 50
                    fprintf('Warning: Skipping event detection for trial with more than 50 (%d) samples.', numel(time));
                  end
                  events = struct();
                end

                % Convert detected events into masks
                if isfield(events, 'saccades')
                    obj.data(t).saccade_mask = idf_mask_cluster(events.saccades, length(time));
                else
                    obj.data(t).saccade_mask = zeros(length(time), 1);
                end
                
                if isfield(events, 'fixations')
                    obj.data(t).fixation_mask = idf_mask_cluster(events.fixations, length(time));
                else
                    obj.data(t).fixation_mask = zeros(length(time), 1);
                end
            end
        end        
    end
end