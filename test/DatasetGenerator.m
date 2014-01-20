function DatasetGenerator(cfg)

    function time = generate_samples(scfg)
    % GENERATE_SAMPLES  Writes all samples for a given trial 
    % to the datafile.
    %
    % Trials:
    %  1. Constant fixation for entire duration
    %     - ROI: Frames 1, 11, 21, 41
    %                   81, 121, 251, 301 and 501 are scene changes.
    %     - One big ROI for full frame
    %
    %  2. Fixation jumps from left to right half of screen every 50 frames.
    %     - ROI Frame A -> 200 frames full frame
    %     - ROI Frame A/b -> 100 frames left/right
    %     - ROI Frame A/b -> 100 frames right/left
    %     - ROI Frame A/b -> 100 frames left/right
    %     - ROI Frame A/B -> until n-100 frames B left, A hidden
    %     - ROI Frame C -> last 150 frames
    %
    %  3. Other frames, the fixation is constantly on the left.
    %     - ROI jumps A left, B right; 
    %                 A right, B left; 
    %                 A disabled, B disabled every 100 frames.
    %  

        time = scfg.startTime;
        fid = scfg.datasetFile;
        
        timePerSample = 1000000/500;
        timePerFrame = 1000000/30;
        
        samplesPerFrame = ceil(timePerFrame / timePerSample);
        
        fprintf(fid, '%d\tMSG\t%d\t# Message: TrialNr: %d\n', time, scfg.trial - 1, scfg.trialNr);
        fprintf(fid, '%d\tMSG\t%d\t# Message: TrialNr: %d\n', time, scfg.trial, scfg.trialNr);
        fprintf(fid, '%d\tMSG\t%d\t# Message: Movie: %s\n', time, scfg.trial, scfg.filename);
        
        for i = 1:scfg.frameCount
            
            fprintf(fid, '%d\tMSG\t%d\t# Message: FrameNr: %d\n', time, scfg.trial, i);
            fprintf(fid, '%d\tMSG\t%d\t# Message: Frame: %d\n', time, scfg.trial, i);
            
            for j = 1:samplesPerFrame
                time = time + 2000;
                x = 0; y = 0;

                switch scfg.trialNr
                    case 1
                        x = scfg.screenDims(1) / 2;
                        y = scfg.screenDims(2) / 2;
                    case 2
                        if mod(i, 100) < 50
                            x = scfg.screenDims(1) * 0.25;
                            y = scfg.screenDims(2) / 2;                            
                        else
                            x = scfg.screenDims(1) * 0.75;
                            y = scfg.screenDims(2) / 2;
                        end;
                    case 3
                        x = scfg.screenDims(1) / 4;
                        y = scfg.screenDims(2) / 2;                        
                end
                
                fprintf(fid, '%d\tSMP\t%d\t0.0\t0.0\t0.0\t0.0\t0.0\t0.0\t%.2f\t%.2f\n', time, scfg.trial, x, y);
            end
        end
    end


    function main(cfg)
        cfg.datasetFile = fopen(cfg.datasetFilename, 'w');
        
        cfg.startTime = 0;
        time = cfg.startTime;

        write_idf_header(cfg, cfg.datasetFile);
        
        for i = 1:length(cfg.stimuli)
            stimulus = VideoROIStimulus();
            stimulus.openStimulus(cfg.stimuli{i});
            
            scfg = struct();
            scfg.frameRate = stimulus.getFrameRate();
            scfg.frameCount = stimulus.getNumberOfFrames();            
            scfg.frameDims = [stimulus.getFrameWidth(), stimulus.getFrameHeight()];
            scfg.screenDims = [1024 768];
            
            [~, name, ext] = fileparts(cfg.stimuli{i});
            scfg.filename = [name ext];            
            scfg.startTime = time;
            scfg.trial = i + 20;
            scfg.trialNr = i;
            scfg.datasetFile = cfg.datasetFile;
            
            time = generate_samples(scfg);            
        end                       

        fclose(cfg.datasetFile);
    end

    main(cfg);
end
