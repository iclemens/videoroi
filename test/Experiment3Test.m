function Experiment3Test(cfg)
  
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
        {750, 350, 100; 9250, 100, 350; 250, 350, 100}, ...
        {750, 350, 600; 9250, 600, 350; 250, 350, 600}, ...
        {750, 350, 350; 9250, 350, 350; 250, 350, 350} ...
        ... %  - Fixation jumps every 400ms, Outside image -> ROI 1 -> Image -> ROI 2 -> ROI 3 -> Outside
        %{}
        };
    end
  
  
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
        eopMsgTime = pctMsgTime + scfg.fixationDuration + scfg.trialDuration;        
        
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

          if ptr < size(scfg.scenario, 1) && time >= scfg.scenario{ptr, 1}
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

    end
    
    main(cfg);

end
