function Experiment3Test(cfg)
  
    function time = generate_samples(scfg)
    % GENERATE_SAMPLES  Writes all samples for a given trial 
    % to the datafile.
    %
    % All trials are structured similarly:
    %  [PRE-FIXATION, FIXATION, PICTURE, POST-PICTURE] = [500, 500, 9000, 500]
    %
    % Scenarios:
    %  - Constant fixation for entire duration (inside image)
    %   1. ROI Full image
    %   2. ROI Outside fixation
    %   3. ROI Around fixation
    %
    %  - Fixation jumps to image 1000ms after image onset and away 1000ms before image offset.
    %   4. ROI Full image
    %   5. ROI Outside fixation
    %   6. ROI Around fixation
    %  - Fixation jumps to image 1000ms before image onset and away at image offset.
    %   7. ROI Full image
    %   8. ROI Outside fixation
    %   9. ROI Around fixation
    %
    %  - Fixation jumps every 400ms, Outside image -> ROI 1 -> Image -> ROI 2 -> ROI 3 -> Outside
    %   10. Three regions of interest
    %

        if ~isfield(scfg, 'fixationDuration'), scfg.fixationDuration = 500 * 1000; end
        if ~isfield(scfg, 'trialDuration'), scfg.trialDuration = 9000 * 1000; end
        
        time = scfg.startTime;
        fid = scfg.datasetFile;
        
        fixMsgTime = time + 500 * 1000;
        pctMsgTime = fixMsgTime + scfg.fixationDuration;
        eopMsgTime = pctMsgTime + scfg.fixationDuration + scfg.trialDuration;        
        
        fixMsgFlag = 0;
        pctMsgFlag = 0;
        eopMsgFlag = 0;        
        
        numberOfSamples = (500 * 1000 + eopMsgTime - time) / 2;
        
        fprintf(fid, '%d\tMSG\t%d\t# Message: New trial: TrialNr = %d\n', time, scfg.trial - 1, scfg.trialNr);

        for j = 1:numberOfSamples
          time = time + 2000;

          x = 0; y = 0;

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


    function main(cfg)
      
        % Some random stimuli
        if ~isfield('stimuli', cfg)
          cfg.stimuli = { ...
            'Rafd090_26_Caucasian_female_fearful_frontal.jpg', ...
            'Rafd090_05_Caucasian_male_angry_frontal.jpg', ...
            'Rafd090_71_Caucasian_male_sad_frontal.jpg', ...
            'Rafd090_33_Caucasian_male_happy_frontal.jpg' ...
            };
        end

        cfg.datasetFile = fopen(cfg.datasetFilename, 'w');
        
        cfg.startTime = 0;
        cfg.experiment = 3;
        time = cfg.startTime;

        write_idf_header(cfg, cfg.datasetFile);
        
        % Loop over trials (one per stimulus)
        for i = 1:length(cfg.stimuli)
            stimulus = VideoROIStimulus();
            stimulus.openStimulus(cfg.stimuli{i});
            
            scfg = struct();
            scfg.picturePosition = [279 34];
                        
            [~, name, ext] = fileparts(cfg.stimuli{i});
            scfg.filename = [name ext];
            scfg.startTime = time;
            scfg.trial = i;
            scfg.trialNr = i;
            scfg.datasetFile = cfg.datasetFile;
            
            time = generate_samples(scfg);            
        end                       

        fclose(cfg.datasetFile);
    end

    main(cfg);

end
