function VideoROIAnalysis(cfg)
%
% Performs the ROI analysis.
%
%  cfg.projectDirectory  specifies the project data to be analyzed
%  cfg.outputFile  specifies where the output should be written to
%  cfg.units  specifies the time-units used (us, ms, or s)
%  cfg.ignoreafterscenechange  Amount of time (in seconds) to ignore after a scene has changed.
%  cfg.minimumfixationduration  Minimum duration (in seconds) of a fixation.
%

    if nargin < 1, cfg = struct; end;

    vr_initialize();
    cfg = vr_checkconfig(cfg, 'defaults', {'units', 'us'});
    
    if isfield(cfg, 'project') && isfield(cfg, 'projectdirectory')
      error('VideoROIAnalysis:cfgError', 'Configuration cannot both contain project and projectDirectory.');
    end
    
    if isfield(cfg, 'project')
      cfg = vr_checkconfig(cfg, 'validate', {'project', @(v) isa(v, 'VideoROIProject')});
    else
      cfg = vr_checkconfig(cfg, 'defaults', {'projectdirectory', @(x) uigetdir('', 'Open project directory')});
      cfg = vr_checkconfig(cfg, 'validate', {'projectdirectory', @(v) ~isempty(v) && ischar(v) && exist(v, 'dir') == 7});
    end
    
    cfg = vr_checkconfig(cfg, 'defaults', {'outputfile', fullfile(cfg.projectdirectory, 'output.csv')});   
    cfg = vr_checkconfig(cfg, 'defaults', {'ignoreafterscenechange', 0.15});
    cfg = vr_checkconfig(cfg, 'defaults', {'minimumfixationduration', 0.10});
    cfg = vr_checkconfig(cfg, 'defaults', {'method', 'highest_score'});
    
    % Open project and output file
    if isfield(cfg, 'project')
      project = cfg.project;
    else
      project = VideoROIProject(cfg.projectdirectory);
    end
    
    [outputFile, message] = fopen(cfg.outputfile, 'w');
    if(outputFile == -1), error(['could not open output file: ' message]); end

    fprintf(outputFile, '"dataset", "stimulus", "roi_name", "roi", "f_fix_start", "t_fix_start", "f_fix_stop", "t_fix_stop", "fix_duration", "overlap"\r\n');

    numDatasets = project.getNumberOfDatasets();
    for d = 1:numDatasets
        dataset_info = project.getInfoForDataset(d);
        disp(['Processing ' num2str(d) ': ' dataset_info.name]);
                
        data = [];
        data.labels = {'px', 'py', 'fixation_mask', 'saccade_mask'};
        
        % Load dataset and trials
        dataset = VideoROIDataset(dataset_info, project.getTaskName());
        stimuli = cell(1, dataset.getNumberOfTrials());
        for t = 1:dataset.getNumberOfTrials();
            stimuli{t} = dataset.getStimuliForTrial(t);
            [samples, columns] = dataset.getAnnotationsForTrial(t);
            data.time{t} = samples(:, 1);
            data.trials{t} = samples(:, 2:end);
        end;       

        if strcmp(cfg.method, 'highest_score')
            scfg = [];
            scfg.project = project;
            scfg.units = cfg.units;
            scfg.ignoreafterscenechange = cfg.ignoreafterscenechange;
            scfg.minimumfixationduration = cfg.minimumfixationduration;
            scfg.stimuli = stimuli;

            [fixations, regionlabels] = vr_assignclusters(scfg, data);
        elseif strcmp(cfg.method, 'sub_fixation')       
            % Assign regions to samples
            scfg = [];
            scfg.project = project;
            scfg.ignoreafterscenechange = cfg.ignoreafterscenechange;
            scfg.minimumfixationduration = cfg.minimumfixationduration;        
            scfg.stimuli = stimuli;
            [output, regionlabels] = vr_assignregions(scfg, data);

            % Cluster fixations by region
            scfg = [];
            scfg.outputfile = outputFile;
            scfg.units = cfg.units;
            scfg.minimumfixationduration = cfg.minimumfixationduration;
            fixations = vr_clusterfixations(scfg, output);
        else
            error('Unknown ROI assignment method specified.');
        end;
        
        % Write fixations to file
        for t = 1:length(fixations.trials)
            for c = 1:size(fixations.trials{t})
                if fixations.trials{t}(c, 2) == 0
                    region_label = 'OutsideRegions';
                else
                    region_label = regionlabels{t}{fixations.trials{t}(c, 2)};
                end
                
                if fixations.trials{t}(c, 1) == 0
                    stim_label = 'OutsideStimuli';
                else
                    stim_label = stimuli{t}(fixations.trials{t}(c, 1)).name;
                end

                fprintf(outputFile, sprintf('"%s", "%s", "%s", %d, %d, %d, %d, %d, %d, %.2f\r\n', ...
                    dataset_info.name, ...
                    stim_label, ...
                    region_label, ...
                    fixations.trials{t}(c, 2), ...
                    fixations.trials{t}(c, 3), ...
                    fixations.trials{t}(c, 4), ...
                    fixations.trials{t}(c, 5), ...
                    fixations.trials{t}(c, 6), ...
                    fixations.trials{t}(c, 7), ...
                    fixations.trials{t}(c, 8)));
                
            end;
        end;
        
    end

    % Close output
    fclose(outputFile);
end

