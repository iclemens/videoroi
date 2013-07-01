function DatasetGenerator(cfg)

    function write_header(cfg)
    % WRITE_HEADER  Writes the file header.
    
        fid = cfg.datasetFile;
        
        if(~isfield(cfg, 'columns'))
            cfg.columns = {'Time', 'Type', 'Trial', ...
                'R Raw X [px]', 'R Raw Y [px]', 'R Dia X [px]', 'R Dia Y [px]', ...
                'R CR1 X [px]', 'R CR1 Y [px]', 'R POR X [px]', 'R POR Y [px]'};
        end;
        
        if(~isfield(cfg, 'sampleRate')), cfg.sampleRate = 500; end;
        if(~isfield(cfg, 'sampleCount')), cfg.sampleCount = 1000; end;
        if(~isfield(cfg, 'screenResolution')), cfg.screenResolution = [1024 768]; end;
        
        fprintf(fid, '## [iView]\n');
        fprintf(fid, '## Converted from: generated.idf\n');
        fprintf(fid, '## Date: %s\n', datestr(now, 'dd.mm.yyyy hh:MM:ss'));
        fprintf(fid, '## Version: IDF Converter 3.0.8\n');
        fprintf(fid, '## Sample Rate: %d\n', cfg.sampleRate);
        
        fprintf(fid, '## [Run]\n');
        fprintf(fid, '## Subject:	Experiment4_s102\n');
        fprintf(fid, '## Description:\n');
        fprintf(fid, '## [Calibration]\n');
        fprintf(fid, '## Calibration Type:	13-point\n');
        fprintf(fid, '## Calibration Area:	%d %d\n', cfg.screenResolution(1), cfg.screenResolution(2));
        fprintf(fid, '## [Geometry]\n');
        fprintf(fid, '## Stimulus Dimension [mm]:	340	270\n');
        fprintf(fid, '## Head Distance [mm]:	500\n');
        fprintf(fid, '## [Hardware Setup]\n');
        fprintf(fid, '## [Presentation]\n');
        fprintf(fid, '## Number of Samples:	%d\n', cfg.sampleCount);
        fprintf(fid, '## Reversed:	none\n');
        fprintf(fid, '## Format:	RIGHT, RAW, DIAMETER, CR, POR, MSG\n');
        fprintf(fid, '## \n');
        fprintf(fid, '\n');
        
        fprintf(fid, '%s\n', strjoin(cfg.columns, '\t'));
    end  

    function time = generate_samples(scfg)
    % GENERATE_SAMPLES  Writes all samples for a given trial 
    % to the datafile.
    %
    % Trials:
    %  1. Constant fixation for entire duration
    %     - ROI: Every 10th frame is a new scene
    %     - One big ROI for full frame
    %
    %  2. Fixation jumps from left to right half of screen every 100 frames.
    %     - ROI: Full frame
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

        write_header(cfg);
        
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