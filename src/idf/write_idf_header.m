function write_idf_header(cfg, fid)
% WRITE_HEADER  Writes the file header.

  function out = strjoin(elements, sep)
    % Joins string like so:
    %  STR1 SEP STR2 SEP STR3

    out = elements{1};
    
    for i = 2:numel(elements)
      out = [out sep elements{i}];
    end
  end

  if(~isfield(cfg, 'columns'))
      cfg.columns = {'Time', 'Type', 'Trial', ...
          'R Raw X [px]', 'R Raw Y [px]', 'R Dia X [px]', 'R Dia Y [px]', ...
          'R CR1 X [px]', 'R CR1 Y [px]', 'R POR X [px]', 'R POR Y [px]'};
  end;

  if(~isfield(cfg, 'sampleRate')), cfg.sampleRate = 500; end;
  if(~isfield(cfg, 'sampleCount')), cfg.sampleCount = 1000; end;
  if(~isfield(cfg, 'screenResolution')), cfg.screenResolution = [1024 768]; end;
  if(~isfield(cfg, 'experiment')), cfg.experiment = 4; end;
  if(~isfield(cfg, 'participant')), cfg.participant = 102; end;

  fprintf(fid, '## [iView]\n');
  fprintf(fid, '## Converted from: generated.idf\n');
  fprintf(fid, '## Date: %s\n', datestr(now, 'dd.mm.yyyy hh:MM:ss'));
  fprintf(fid, '## Version: IDF Converter 3.0.8\n');
  fprintf(fid, '## Sample Rate: %d\n', cfg.sampleRate);

  fprintf(fid, '## [Run]\n');
  fprintf(fid, '## Subject:	Experiment%d_s%d\n', cfg.experiment, cfg.participant);
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
