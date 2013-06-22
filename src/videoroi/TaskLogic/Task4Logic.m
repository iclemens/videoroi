classdef Task4Logic < handle
%
% Implements logic specific to Gerine her fourth experiment.
%

    % Settings
    properties(Access = private)
 
        % Minimal saccade velocity (rad / s)
        saccadeThreshold = degtorad(45);

        % Maximum allowable deviation from initial saccade direction (rad)
        extensionAngleThreshold = 0.5 * pi;
        
        % Minimum duration of fixation (in seconds)
        minimumFixationDuration = 0.1;
        
        % Discard time period after scene change (in seconds)
        discardDataAfterChange = 0.1;
    end

    methods(Access = public)
        
        
        function obj = Task4Logic()
        end
        
        
        function data = parseStimulusMsgs(~, data)
            % Find the stimuli presented in each trial
            
            frameData = idf_parse_frame_msgs(data);            
            
            for t = 1:length(data)
                frameNrs = unique(frameData(t).frames);
                frameNrs(isnan(frameNrs)) = [];

                s = 1;
                
                for f = frameNrs'
                    frameSamples = find(frameData(t).frames == f);
                    
                    data(t).stimulus(s).name = frameData(t).movie;
                    data(t).stimulus(s).frame = f;
                    data(t).stimulus(s).onset = frameSamples(1);
                    data(t).stimulus(s).offset = frameSamples(end);
                    data(t).stimulus(s).position = [0 0 1024 768];
                    s = s + 1;
                end
            end
        end


        % Regions are stored in image coordinates, they should first be
        % converted into screen coordinates.
        
        % First clean up the fixtion_mask:
        % 1. Remove fixations which are shorter than the minimum duration
        % 2. Remove samples where no stimuli were presented.
        % 3. Remove first Xms after scene change (new image presentation,
        % scene change flag in ROI file).
        % 
        % We are now left with valid fixations only.
        % 4. For each region determine when fixation was in that region
        % 5. Group longer fixation periods        

        
        function transformStimulusToScreenCoords(stimPresent, positions)
            % Converts stimulus to screen coordinates
            %  Stimulus - Stimulus presentation information
            %  Positions - Coordinates [x y w h] re. stimulus
            
            
            positions = positions ./ stimulusScale .* presentationScale;
            positions(:, 1:2) = positions(:, 1:2) + presentationOffset;
            
            %positions(:, 1:2) 
            
        end
        
        
        function performAnalysisTrial(obj, project, dataset, t)
            [samples, columns] = dataset.getAnnotationsForTrial(t);
            stimuli = dataset.getStimuliForTrial(t);
            
            col_time = strcmp(columns, 'Time');
            col_fix = strcmp(columns, 'Fixation mask');
            
            first_region_column = length(columns) + 1;
            
            loadedStimulus = '';
            
            % Fixme: sort list of stimuli by name
            
            for s = 1:length(stimuli)
                if(~strcmp(loadedStimulus, stimuli(s).name))
                    loadedStimulus = stimuli(s).name;
                    
                    stimulusInfo = project.getInfoForStimulus(stimuli(s).name);
                    roiFile = obj.getLatestROIFilename(stimulusInfo);
                    regions = VideoROIRegions(stimulusInfo);
                    regions.loadRegionsFromFile(roiFile);
                    
                    % Allocate region columns
                    numRegions = regions.getNumberOfRegions();
                    col_regions = nan(1, numRegions);
                    
                    for r = 1:numRegions
                        columns{end + 1} = regions.getLabelForRegion(r);
                        col_regions(r) = length(columns);
                    end;
                    
                end
                
                [states, positions, sceneChange] = regions.getFrameInfo(stimuli(s).frame);
                
                % If first frame, then skip the first couple of
                % milliseconds...
                if(stimuli(s).frame == 0 || sceneChange)
                    stimuli(s).onset
                    
                    tonset = samples(stimuli(s).onset, col_time);
                    mask = samples(:, col_time) >= tonset & ...
                        samples(:, col_time) <= (tonset + 1e6 * obj.discardDataAfterChange);
                    
                    samples(mask, col_fix) = 0;
                end

                

                % Perform actual ROI analysis
            end
        end
        
        function performAnalysis(obj, project)
            numDatasets = project.getNumberOfDatasets();

            for d = 1:numDatasets
                
                % Obtain eye traces
                datasetInfo = project.getInfoForDataset(d);
                dataset = VideoROIDataset(datasetInfo, taskName);
                
                numTrials = dataset.getNumberOfTrials();
                
                for t = 1:numTrials                
                    obj.performAnalysisTrial(project, dataset, t);

                    % Add output stage about here...
                end               
            end;
   
        end
    end

end
