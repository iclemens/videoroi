function VideoROIStatistics(cfg)
%
% Collects statistics about the regions of interest in each video/stimulus.
%
%  Per dataset per trial:
%   total time in roi
%   total fixation time
%   total roi area (pixels x frames)
%   total roi display time / roi are
%   total trial duration
%

    vr_initialize();
    cfg = vr_checkconfig(cfg, 'defaults', {'projectdirectory', @(x) uigetdir('', 'Open project directory')});    
    cfg = vr_checkconfig(cfg, 'validate', {'projectdirectory', @(v) ~isempty(v) && ischar(v) && exist(v, 'dir') == 7});
    cfg = vr_checkconfig(cfg, 'defaults', {'outputfile', fullfile(cfg.projectdirectory, 'statistics.csv')});   

    
    % Open project and output file
    project = VideoROIProject(cfg.projectdirectory);
    [outputFile, message] = fopen(cfg.outputfile, 'w');
    if(outputFile == -1), error(['could not open output file: ' message]); end

    %fprintf(outputFile, '"dataset", "stimulus", "roi_name", "roi", "f_fix_start", "t_fix_start", "f_fix_stop", "t_fix_stop", "fix_duration", "overlap"\r\n');

    numDatasets = project.getNumberOfDatasets();
    for d = 1:numDatasets
        dataset_info = project.getInfoForDataset(d);
        
        % Load dataset and trials
        dataset = VideoROIDataset(dataset_info, 'Task4Logic');
        stimuli = cell(1, dataset.getNumberOfTrials());
        for t = 1:dataset.getNumberOfTrials();
            stimuli{t} = dataset.getStimuliForTrial(t);
            
            stimuli{t}
            
            
                        region_filename = cfg.project.getLatestROIFilename(stimulus_info);
            regions = VideoROIRegions(stimulus_info);

            if(isempty(region_filename))
                disp(['Warning: No ROIs defined for stimulus ' stimulus_info.name]);
                break;
            end

            if(~exist(region_filename, 'file'))
                disp(['Warning: File ' region_filename ' does not exist']);
                break;
            end

            regions.loadRegionsFromFile(region_filename);

            
            %for s = 1:length(stimuli{t})
                %stimulus_info{t} = get_stimulus_info(project, stimuli{t}(s).name);
            %end
        end;       

        
    end

    % Close output
    fclose(outputFile);

    

    function stimulus_info = get_stimulus_info(project, name)
    % GET_STIMULUS_INFO  Find and return information about the 
    % stimulus with name [name] in the specified project.    
    
        stimulus_info = project.getInfoForStimulus(name);
                
        if(isnan(stimulus_info))
            dots = find(name == '.');            
            stimulus_info = project.getInfoForStimulus(name(1:dots(end) - 1));
        end 
    end     
    
end