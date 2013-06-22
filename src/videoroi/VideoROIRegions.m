classdef VideoROIRegions < handle
%
% Keeps track of all regions of interest within a stimulus.
% In addition it supports saving and loading of ROI files.
%

    properties(Access = private)
        % Meta-data describing the stimulus
        stimInfo;

        numFrames = 0;
        numROIs;
        
        % Cell array containing a label for each of the ROIs
        roiLabels;
        
        % Matrix (ROI x Frame) containing the state
        %  NaN => From previous frame; 0 => Disabled; 1 => Enabled        
        roiStates;
        
        % Matrix ROI x Frame x {X Y W H} containing
        %  the location of each ROI in each frame
        %  how this value is used depends on roiState
        roiPositions;
        
        sceneChanges;        
    end
    
    methods(Access = public)
        
        function obj = VideoROIRegions(stimInfo)
            % Initializes data structures
            obj.updateStimulus(stimInfo);
        end                      
        
        
        function clearRegions(obj)
            % Removes all ROIs
            
            obj.numROIs = 0;
            obj.roiLabels = {};
            
            obj.roiStates = [zeros(obj.numROIs, 1) nan(obj.numROIs, obj.numFrames - 1)];
            obj.roiPositions = ones(obj.numROIs, obj.numFrames, 4);
            obj.roiPositions(:, :, 3:4) = obj.roiPositions(:, :, 3:4) * 10;
            
            if(obj.numFrames == 0)
                obj.sceneChanges = [];
            else
                obj.sceneChanges = [1 zeros(1, obj.numFrames - 1)];
            end;
        end

        
                        
        function numROIs = getNumberOfRegions(obj)
            % Returns the number of regions defined
            
            numROIs = obj.numROIs;
        end
        
        
        function label = getLabelForRegion(obj, roi)
            % Returns the label for a given ROI
            
            label = obj.roiLabels{roi};
        end        
                                        
        
        function addRegion(obj, label, startFrame)
            % Add an ROI and setup states and positions accordingly
            
            if(any(strcmp(obj.roiLabels, label)))
                disp('An ROI with that name already exist');
                return;
            end
            
            obj.roiLabels{end + 1} = label;
            obj.numROIs = length(obj.roiLabels);
            
            x = mod(obj.numROIs - 1, 6) * 60 + 1;
            y = floor((obj.numROIs - 1) / 6) * 60 + 1;
            
            obj.roiStates(end + 1, 1:obj.numFrames) = [0 nan(1, obj.numFrames - 1)];
            obj.roiStates(end, startFrame) = 1;
            
            obj.roiPositions(end + 1, 1:obj.numFrames, 1:4) = ...
                shiftdim([x * ones(obj.numFrames, 1), ...
                          y * ones(obj.numFrames, 1), ...
                          50 * ones(obj.numFrames, 2)]);
            
            fprintf('Engine: Added ROI "%s"\n', label);
        end
        
        
        function removeRegion(obj, label)
            % Removes an ROI and associated states/positions
            
            index = find(strcmp(obj.roiLabels, label));
            
            if(length(index) ~= 1)
                disp('An ROI with that name does not exist');
                return;
            end
            
            obj.roiLabels(index) = [];
            obj.roiStates(index, :, :) = [];
            obj.roiPositions(index, :, :) = [];
            
            obj.numROIs = length(obj.roiLabels);
            
            fprintf('Engine: Removed ROI "%s"\n', label);
        end
        
                
        % Retrieves ROI state and position information associated with a frame.
        function [states, positions, sceneChange] = getFrameInfo(obj, index)
            if(isempty(index))
                error('No frame number given');
            end
            
            if(index < 1 || index > obj.numFrames)
                error('Frame number out of bounds');
            end            
          
            states = obj.roiStates(:, index);
            positions = obj.roiPositions(:, index, :);
            sceneChange = obj.sceneChanges(1, index);
            
            for i = 1:obj.numROIs
                if(isnan(states(i)))
                    lastIndex = obj.getLastValidState(index, i);
                    
                    sprintf('State is undefined; using position from %d\n', lastIndex);
                    
                    states(i) = obj.roiStates(i, lastIndex);
                    positions(i, 1, :) = obj.roiPositions(i, lastIndex, :);                    
                end
            end
        end

        
        function setRegionState(obj, roi, index, state)
            obj.roiStates(roi, index) = state;
        end

        
        function setRegionPosition(obj, roi, index, position)
            %fprintf('Updating ROI %d on frame %d\n', [roi, index]);
            obj.roiPositions(roi, index, 1:4) = position(:);
            
            % If the state was undefined, enable it
            if(isnan(obj.roiStates(roi, index)))
                obj.roiStates(roi, index) = 1;
            end            
        end
       
        
        function setSceneChange(obj, frame, value)
            obj.sceneChanges(1, frame) = value;
        end
        
        
        function saveRegionsToFile(obj, filename)
            % Saves all ROIs to a file
            
            numROIs = obj.numROIs;
            roiLabels = obj.roiLabels;
            roiStates = obj.roiStates;            
            roiPositions = obj.roiPositions;
            sceneChanges = obj.sceneChanges;
            videoName = obj.stimInfo.name;
            release = 3;
            
            save(filename, 'numROIs', 'roiLabels', 'roiStates', 'roiPositions', 'release', 'sceneChanges', 'videoName');
        end
    
        
        function loadRegionsFromFile(obj, filename)
            % Loads all ROIs from a file
            data = load(filename, '-mat');
            
            if(size(data.roiStates, 2) ~= obj.numFrames)
                error(['Error: the number of frames in ROI file does not match ' ...
                    'the number of stimulus frames']);
            end
            
            obj.numROIs = data.numROIs;
            obj.roiLabels = data.roiLabels;
            obj.roiStates = data.roiStates;            
            obj.roiPositions = data.roiPositions;

            if(~isfield(data, 'release'))
                release = 0; 
            else
                release = data.release;
            end;
            
            if(release >= 2)
                obj.sceneChanges = data.sceneChanges;
            else
                obj.sceneChanges = [1 zeros(1, obj.numFrames - 1)];
            end
            
            if(release >= 3)
                if(~strcmpi(data.videoName, obj.stimInfo.name))
                    disp(['Currently loaded stimulus:       ' obj.stimInfo.name]);
                    disp(['Stimulus loaded at ROI creation: ' data.videoName]);
                                        
                    a = questdlg(['The ROI-file you are trying to load does not match the stimulus.' 10 'Do you want to continue?'], 'Stimulus mismatch', 'Yes', 'No', 'No');
                    
                    if(strcmp(a, 'No'))
                        error('The ROI-file you are trying to load does not match the stimulus.');
                    end
                end
            end
        end
        
    end


    methods(Access = protected)
        
        function lastIndex = getLastValidState(obj, index, roi)
            % Determines the state of the the first frame
            % with an actual state counting from the
            % specified from down to the first frame.
            
            range = index:-1:1;
            stateHistory = obj.roiStates(roi, range);
            validStates = find(~isnan(stateHistory));
            
            % No valid states found, assume disabled
            if(isempty(validStates))
                lastIndex = 1;
                return;
            end
            
            lastIndex = range(validStates(1));
        end
        
        
        function updateStimulus(obj, stimInfo)
            % Resets data-structures to work with a freshly-loaded stimulus
            %
            % Note: this function is private because a new instance should
            % be created for every stimulus. Reusing the instance is
            % theoretically possible but that would not be a very good
            % design.

            obj.stimInfo = stimInfo;
            
            obj.numFrames = obj.stimInfo.frames;
            
            obj.roiStates = [zeros(obj.numROIs, 1) nan(obj.numROIs, obj.numFrames - 1)];
            obj.roiPositions = ones(obj.numROIs, obj.numFrames, 4);
            obj.sceneChanges = [1 zeros(1, obj.numFrames - 1)];
        end
        
    end
end