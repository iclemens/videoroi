function DatasetGenerator(cfg)

    function write_header(cfg)
        fid = cfg.outputFile;
        
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


%7441672318	SMP	22	97.19	84.50	26.00	27.00	111.63	87.68	479.07	404.54
%7441674342	SMP	22	97.17	84.56	24.00	28.00	111.66	87.70	478.75	404.69
%7441676335	SMP	22	97.20	84.51	25.00	27.00	111.63	87.70	479.14	404.35        


    function main(cfg)
        cfg.outputFile = fopen(cfg.outputFilename, 'w');
        
        cfg.sampleCount = 10000;
        
        write_header(cfg);
        
                
        
        fclose(cfg.outputFile);
    end


    main(cfg);

end