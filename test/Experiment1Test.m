function Experiment1Test(cfg)
  
  % Stimulus dimensions:
  %  L 279 W 465
  %  T 34  H 700
  
  % ROI Top (35 to 300) and ROI Bottom (400 to 700)
  
    % ms, x, y
    if ~isfield(cfg, 'scenarios')
      cfg.scenarios = { ...
        ... %  - Constant fixation for entire duration (inside image)
        {15000, 350, 100}, ...  % 1. Fixation inside ROI
        {15000, 200, 600}, ...  % 2. Fixation outside image
        {15000, 350, 350}, ...  % 3. Fixation outside ROI
        ... %  - Fixation jumps to image 1000ms after image onset and away 1000ms before image offset.
        {2000, 350, 100; 7000, 350, 100; 1500, 350, 100}, ...
        {2000, 200, 600; 7000, 200, 600; 1500, 200, 600}, ...
        {2000, 350, 350; 7000, 350, 350; 1500, 350, 350}, ...
        ... % - Fixation jumps to image 250ms before image onset and away at image offset.
        {750, 350, 100; 9250, 350, 100; 250, 350, 100}, ...
        {750, 350, 600; 9250, 350, 600; 250, 350, 600}, ...
        {750, 350, 350; 9250, 350, 350; 250, 350, 350} ...
        ... %  - Fixation jumps every 400ms, Outside image -> ROI 1 -> Image -> ROI 2 -> ROI 3 -> Outside
        { 400, 200, 100;  800, 350, 100; 1600, 350, 350; 2000, 350, 450; ...
         2400, 200, 100; 2800, 350, 100; 3200, 350, 350; 3600, 350, 450;
         4000, 200, 100; 4400, 350, 100; 4800, 350, 350; 5200, 350, 450;
         5600, 200, 100; 6000, 350, 100; 6400, 350, 350; 6800, 350, 450;
         7200, 200, 100; 7600, 350, 100; 8000, 350, 350; 8400, 350, 450;
         8800, 200, 100; 9200, 350, 100; 9600, 350, 350; 10000, 350, 450}         
        };
    end
  
%"fakedata", "26/caucasian/female", "Top", 1, 1, 151, 1, 10999, 10848, 0.88
%"fakedata", "26/caucasian/female", "OutsideRegions", 0, -1, 11002, -1, 21999, 10997, 1.00
%"fakedata", "26/caucasian/female", "OutsideRegions", 0, -1, 22002, -1, 32999, 10997, 1.00

%"fakedata", "26/caucasian/female", "Top", 1, 1, 33002, 1, 43999, 10997, 0.86
%"fakedata", "26/caucasian/female", "OutsideRegions", 0, -1, 44002, -1, 54999, 10997, 1.00
%"fakedata", "26/caucasian/female", "OutsideRegions", 0, -1, 55002, -1, 65999, 10997, 1.00

%"fakedata", "26/caucasian/female", "Top", 1, 1, 66002, 1, 76999, 10997, 0.86
%"fakedata", "26/caucasian/female", "Top", 1, 1, 77002, 1, 87999, 10997, 0.86
%"fakedata", "26/caucasian/female", "OutsideRegions", 0, -1, 88002, -1, 98999, 10997, 1.00
    
  
    function time = generate_samples(scfg)
    % GENERATE_SAMPLES  Writes all samples for a given trial 
    % to the datafile.
    %
    % All trials are structured similarly:
    %  [PRE-FIXATION, FIXATION, PICTURE, POST-PICTURE] = [500, 500, 9000, 500]
    %

        if ~isfield(scfg, 'prefixDuration'), scfg.prefixDuration = 500 * 1000; end
        if ~isfield(scfg, 'fixationDuration'), scfg.fixationDuration = 500 * 1000; end
        if ~isfield(scfg, 'trialDuration'), scfg.trialDuration = 9000 * 1000; end
        if ~isfield(scfg, 'postpctDuration'), scfg.postpctDuration = 500 * 1000; end
        
        time = scfg.startTime;
        fid = scfg.datasetFile;
        
        fixMsgTime = time + scfg.prefixDuration;
        pctMsgTime = fixMsgTime + scfg.fixationDuration;
        eopMsgTime = pctMsgTime + scfg.trialDuration;        
        
        fixMsgFlag = 0;
        pctMsgFlag = 0;
        eopMsgFlag = 0;        
        
        numberOfSamples = (scfg.postpctDuration + eopMsgTime - time) / 2000;
        
        fprintf(fid, '%d\tMSG\t%d\t# Message: New trial: TrialNr = %d\n', time, scfg.trial - 1, scfg.trialNr);

        % Initial point of fixation
        ptr = 1; 
        x = scfg.scenario{1, 2}; 
        y = scfg.scenario{1, 3};
        
        for j = 1:numberOfSamples
          time = time + 2000;

          if ptr < size(scfg.scenario, 1) && ((time-scfg.startTime)/1000) >= scfg.scenario{ptr, 1}
            [ptr (time-scfg.startTime)/1000 scfg.scenario{ptr, 1}]
            ptr = ptr + 1;
            x = scfg.scenario{ptr, 2}; 
            y = scfg.scenario{ptr, 3};
          end
          
          % Inject messages into datafile
          if ~fixMsgFlag && (time >= fixMsgTime)
            fprintf(fid, '%d\tMSG\t%d\t# Message: Fixation\n', time, scfg.trial);
            fixMsgFlag = 1;
          end
          
          if ~pctMsgFlag && (time >= pctMsgTime)
            fprintf(fid, '%d\tMSG\t%d\t# Message: Picture: Left: %d top: %d Name: %s\n', time, scfg.trial, scfg.picturePosition(1), scfg.picturePosition(2), scfg.filename);        
            pctMsgFlag = 1;
          end
          
          if ~eopMsgFlag && (time >= eopMsgTime)
            fprintf(fid, '%d\tMSG\t%d\t# Message: End of Picture\n', time, scfg.trial);
            eopMsgFlag = 1;
            
            % FIXME: At the moment we return to force the end of the current trial.
            return;
          end
          
          % Write sample
          fprintf(fid, '%d\tSMP\t%d\t0.0\t0.0\t0.0\t0.0\t0.0\t0.0\t%.2f\t%.2f\n', time, scfg.trial, x, y);
        end
    end


    function generate_dataset(cfg)
      
        % Some random stimuli
        if ~isfield('stimuli', cfg)
          cfg.stimuli = { ...
            'Rafd090_26_Caucasian_female_fearful_frontal.jpg', ...
            'Rafd090_26_Caucasian_female_fearful_frontal.jpg', ...
            'Rafd090_26_Caucasian_female_fearful_frontal.jpg', ...
            ...
            'Rafd090_26_Caucasian_female_fearful_frontal.jpg', ...
            'Rafd090_26_Caucasian_female_fearful_frontal.jpg', ...
            'Rafd090_26_Caucasian_female_fearful_frontal.jpg', ...
            ...
            'Rafd090_26_Caucasian_female_fearful_frontal.jpg', ...
            'Rafd090_26_Caucasian_female_fearful_frontal.jpg', ...
            'Rafd090_26_Caucasian_female_fearful_frontal.jpg' ...
            'Rafd090_26_Caucasian_female_fearful_frontal.jpg' ...
            };
        end

        cfg.datasetFile = fopen(cfg.datasetFilename, 'w');
        
        cfg.startTime = 0;
        cfg.experiment = 3;
        time = cfg.startTime;

        write_idf_header(cfg, cfg.datasetFile);
        
        % Loop over trials (one per stimulus)
        for i = 1:numel(cfg.scenarios)        
            scfg = struct();
            scfg.datasetFile = cfg.datasetFile;
            scfg.startTime = time;

            scfg.trial = i;
            scfg.trialNr = i;
            
            % Stimulus
            scfg.filename = cfg.stimuli{i};
            scfg.scenario = cfg.scenarios{i};
            scfg.picturePosition = [279 34];
            
            time = generate_samples(scfg);            
        end                       

        fclose(cfg.datasetFile);
    end


    function main(cfg)
        cfg.datasetFilename = 'work/fakedata.txt';
        cfg.analysisFilename = 'work/fakeanalysis.csv';
        generate_dataset(cfg);
        
        % Create project
        mkdir('work/project');
        project = VideoROIProject('work/project');
        project.setTaskName('Task1Logic');
        project.addDataset('work/fakedata.txt', 'fakedata');
        
        if project.getNumberOfStimuli < 1
          project.addStimulus('work/rafd090.jpg', 'Rafd090_26_Caucasian_female_fearful_frontal');
        end

        stimInfo = project.getInfoForStimulus(1);
        roiFilename = project.getNextROIFilename(stimInfo);        
        regions = VideoROIRegions(stimInfo);
        
        regions.addRegion('Top', 1);
        regions.addRegion('Bottom', 1);
        
        regions.setRegionPosition(1, 1, [0 0 465 300])
        regions.setRegionPosition(2, 1, [0 375 465 300])
                
        regions.saveRegionsToFile(roiFilename);       
    end
    
    main(cfg);

end
