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
    cfg = vr_checkconfig(cfg, 'defaults', {'projectdirectory', @(x) uigetdir('', 'Open project directory')});    
    cfg = vr_checkconfig(cfg, 'validate', {'projectdirectory', @(v) ~isempty(v) && ischar(v) && exist(v, 'dir') == 7});
    cfg = vr_checkconfig(cfg, 'defaults', {'outputfile', fullfile(cfg.projectdirectory, 'output.csv')});   
    cfg = vr_checkconfig(cfg, 'defaults', {'ignoreafterscenechange', 0.15});
    cfg = vr_checkconfig(cfg, 'defaults', {'minimumfixationduration', 0.10});

    
    % Open project and output file
    project = VideoROIProject(cfg.projectdirectory);
    [outputFile, message] = fopen(cfg.outputfile, 'w');
    if(outputFile == -1), error(['could not open output file: ' message]); end

    % Write header (fixme: should be done in other function!)
    fprintf(outputFile, '"dataset", "stimulus", "roi_name", "roi", "f_fix_start", "t_fix_start", "f_fix_stop", "t_fix_stop", "fix_duration", "overlap"\r\n');

    numDatasets = project.getNumberOfDatasets();
    for d = 1:numDatasets
        dataset_info = project.getInfoForDataset(d);
        disp(['Processing ' num2str(d) ': ' dataset_info.name]);
                
        data = [];
        data.labels = {'px', 'py', 'fixation_mask', 'saccade_mask'};
        
        % Load dataset and trials
        dataset = VideoROIDataset(dataset_info, 'Task4Logic');
        stimuli = cell(1, dataset.getNumberOfTrials());
        for t = 1:dataset.getNumberOfTrials();
            stimuli{t} = dataset.getStimuliForTrial(t);
            [samples, columns] = dataset.getAnnotationsForTrial(t);
            data.time{t} = samples(:, 1);
            data.trials{t} = samples(:, 2:end);
        end;
        
        scfg = [];
        scfg.project = project;
        scfg.ignoreafterscenechange = cfg.ignoreafterscenechange;
        scfg.minimumfixationduration = cfg.minimumfixationduration;        
        scfg.stimuli = stimuli;
        [output, regionlabels] = vr_assignregions(scfg, data);
        
        scfg = [];
        scfg.datasetname = dataset_info.name;
        scfg.outputfile = outputFile;
        scfg.regionlabels = regionlabels;
        scfg.units = cfg.units;
        scfg.stimuli = stimuli;
        scfg.minimumfixationduration = cfg.minimumfixationduration;
        vr_fixationstofile(scfg, output);
    end

    % Close output
    fclose(outputFile);
end

