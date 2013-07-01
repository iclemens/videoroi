function VideoROIAnalysis(cfg)

    function cfg = fill_defaults(cfg)
    % FILL_DEFAULTS  Fills missing values in the configuration
    %  sturcture with their defaults.
        if(~isfield(cfg, 'projectDirectory'))
            cfg.projectDirectory = uigetdir('', 'Open project directory');
     
            if(isempty(cfg.projectDirectory))
                error('Please choose a valid project directory.');
            end    
        end
        
        if(~isfield(cfg, 'outputFile'))            
            cfg.outputFile = fullfile(cfg.projectDirectory, 'output.csv');
        end
    end


    function stimulus_info = get_stimulus_info(project, name)
    % GET_STIMULUS_INFO  Find and return information about the 
    % stimulus with name [name] in the specified project.
    
        n_stimuli = project.getNumberOfStimuli();

        for i_stimulus = 1:n_stimuli
            stimulus_info = project.getInfoForStimulus(i_stimulus);
            [~, sname, ~] = fileparts(stimulus_info.name);
            [~, name, ~] = fileparts(name);
             
            if strcmpi(sname, name)
                return;
            end
        end
    
        stimulus_info = 0;
    end


    function analysis_result_to_file(cfg, samples)
    % ANALYSIS_RESULT_TO_FILE  Writes the results of the analysis to file.
        clusterRunning = false;
        clusterStarted = 1;
        
        % Only keep time, fixation mask, stimulus and roi number
        samples = samples(:, [1 4 6 7]);
        
        for s = 1:size(samples, 1)
            % Fixation cluster started
            if(~clusterRunning && samples(s, 2))
                clusterRunning = true;
                clusterStarted = s;
                regionStarted = s;
            end
           
            % Region of interest has changed
            if(clusterRunning && s > 1 && samples(s - 1, 3) > 0 && ...
                    ((samples(s, 4) ~= samples(regionStarted, 4)) || ...
                    ~(samples(s, 2))) ...
                )
                duration = samples(s-1, 1) - samples(regionStarted, 1);
                
                if(samples(s-1, 4) == 0)
                    regionLabel = 'OutsideRegions';
                else
                    regionLabel = cfg.regionLabels{ samples(s - 1, 3) }{samples(s - 1, 4)};
                end

                fprintf(cfg.outputFile, '"%s", "%s", "%s", %d, %d, %d, %d\r\n', ...
                    cfg.dataset_info.name, ...
                    cfg.stimuli( samples(s-1,3) ).name, ...
                    regionLabel, ...
                    samples(s-1, 4), ...
                    samples(regionStarted, 1), ...
                    samples(s-1, 1), ...
                    duration);
                
                regionStarted = s;
            end
            
            % Fixation stopped
            if(clusterRunning && ~samples(s, 2))
                clusterRunning = false;
                duration = samples(s-1, 1) - samples(clusterStarted, 1);
                
                % check fixation duration...
                if(duration / 1000 / 1000 < cfg.minimum_fixation_duration)
                    disp('Warning: should discard this fixation!');
                end
            end;            
        end
    end


    function perform_analysis_trial(cfg)
    % PERFORM_ANALYSIS_TRIAL  Peforms the analysis for a single trial only.
    
        [samples, columns] = cfg.dataset.getAnnotationsForTrial(cfg.trial_index);
        % Note: Columns should be:
        %  Time, PX, PY, Fixation Mask, Saccade Mask        
               
        % We add more columns, set overlap to zero to indicate no overlap
        samples(:, end + 1) = 0;   % Stimulus #
        samples(:, end + 1) = 0;   % ROI number
        samples(:, end + 1) = 0;   % Overlap              
        samples(:, end + 1) = 0;   % Ignore flag
        
        
        regionLabels = cell(1, length(cfg.stimuli));
        
        for s = 1:length(cfg.stimuli)
            % Get stimulus/frame information
            stimulus_info = get_stimulus_info(cfg.project, cfg.stimuli(s).name);
            if(~isstruct(stimulus_info)), continue; end;

            frame = cfg.stimuli(s).frame;            
            if(frame == 0), continue; end;
            
            % Samples that belong to stimulus
            sample_slc = cfg.stimuli(s).onset:cfg.stimuli(s).offset;
            
            % Load regions of interest
            region_filename = cfg.project.getLatestROIFilename(stimulus_info);
            regions = VideoROIRegions(stimulus_info);
            
            if(isempty(region_filename))
                disp(['Warning: No ROIs defined for stimulus ' stimulus_info.name]);
                break;
            end
            
            regions.loadRegionsFromFile(region_filename);
            
            % Get ROI data
            [roiState, roiPosition, sceneChange] = regions.getFrameInfo(frame);            
            roiPosition(:, :, [1 3]) = roiPosition(:, :, [1 3]) ./ 640 .* 1024;
            roiPosition(:, :, [2 4]) = roiPosition(:, :, [2 4]) ./ 640 .* 1024;
            
            regionLabels{s} = cell(1, length(roiState));            
            
            % Add stimulus number to samples
            samples(sample_slc, 6) = s;
            
            % Assign ROIs to samples
            for r = 1:length(roiState)
                % Disabled, skip this region
                if(~roiState(r)), continue; end;
                
                % Compute region corners
                position = squeeze(roiPosition(r, :));
                xr = position(1) + [0 position(3)];
                yr = position(2) + [0 position(4)];
                
                x_in_region = (samples(sample_slc, 2) > xr(1)) .* (samples(sample_slc, 2) < xr(2));
                y_in_region = (samples(sample_slc, 3) > yr(1)) .* (samples(sample_slc, 3) < yr(2));
                in_region = (x_in_region .* y_in_region);
                
                update = in_region > samples(sample_slc, 8);
                samples(sample_slc(update), 7) = r;
                samples(sample_slc(update), 8) = in_region(update);
                
                regionLabels{s}{r} = regions.getLabelForRegion(r);
            end;

            % Mark samples to be ignored
            if(sceneChange)                
                t = (samples(:, 1) - samples(sample_slc(1), 1)) / 1000 / 1000;                
                samples(t >= 0 & t <= cfg.ignore_after_scene_change, 9) = 1;
            end
        end;

        % Clear fixation mask on marked samples
        samples(samples(:, 9) == 1, [4 7:8]) = 0;
                
        cfg.regionLabels = regionLabels;
        analysis_result_to_file(cfg, samples);
        
        % FIXME: We need some visualization here to verify that
        %  the samples matrix is correct.
    end


    function perform_analysis(cfg)
    % PERFORM_ANALYSIS  Perform analysis for all datasets and all trials.

        % Open project
        project = VideoROIProject(cfg.projectDirectory);
        
        % Open output file and write header
        outputFile = fopen(cfg.outputFile, 'w');        
        fprintf(outputFile, '"dataset", "stimulus", "roi_name", "roi", "t_fix_start", "t_fix_stop", "fix_duration"\r\n');
                        
        numDatasets = project.getNumberOfDatasets();        
        
        % Loop over datasets and trials
        for d = 1:numDatasets
            dataset_info = project.getInfoForDataset(d);
            disp(['Processing ' num2str(d) ': ' dataset_info.name]);
            dataset = VideoROIDataset(dataset_info, 'Task4Logic');

            for t = 1:dataset.getNumberOfTrials();
                stimuli = dataset.getStimuliForTrial(t);

                cfg = struct();
                cfg.trial_index = t;
                cfg.project = project;
                cfg.outputFile = outputFile;
                cfg.dataset_info = dataset_info;
                
                cfg.dataset = dataset;
                cfg.stimuli = stimuli;
                
                cfg.ignore_after_scene_change = 0.1;   
                cfg.minimum_fixation_duration = 0.1;
                
                perform_analysis_trial(cfg);
            end
        end
        
        % Close output
        fclose(outputFile);
    end

    % Determine directory where m-file is located
    path = fileparts(mfilename('fullpath'));
    path = fullfile(path, '..', 'src');

    % Add source directories to path
    addpath(path);
    addpath(fullfile(path, 'idf'));
    addpath(fullfile(path, 'gui'));
    addpath(fullfile(path, 'gui/controls'));
    addpath(fullfile(path, 'videoroi'));
    addpath(fullfile(path, 'mmread'));

    % Add default values to configuration structure
    if nargin < 1, cfg = struct; end;
    cfg = fill_defaults(cfg);
    
    % Then perform analysis
    perform_analysis(cfg);
end