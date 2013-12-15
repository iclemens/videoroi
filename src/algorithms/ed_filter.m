function [pos, vel, acc] = ed_filter(cfg, pos)
%
% Compute velocity and acceleration given gaze positions.
%
%  cfg - Configuration structure with fields:
%         - frequency in hertz
%         - minimum_saccade_duration in seconds
%
%  pos - nx1 or nx2 matrix of gaze positions (in radians)
%        Columns are components (horizontal and vertical)
%
% Based on code by:
%  Markus Nystrom and Kenneth Holmqvist (2009)
%  Julian Tramper (2011)
%

  % Only one component is present, set vertical component to zero.
  if size(pos, 2) == 1, pos(:, 2) = 0; end;
  if size(pos, 2) ~= 2, error('Position vector has an invalid shape'); end;

  if ~isfield(cfg, 'frequency'), error('No frequency specified'); end;
  if ~isfield(cfg, 'minimum_saccade_duration'), cfg.minimum_saccade_duration = 0.010; end;  
  
  if ~(isreal(cfg.frequency) && ~isnan(cfg.frequency))
    error('Invalid frequency specified');
  end;
  
  if ~(isreal(cfg.minimum_saccade_duration) && ~isnan(cfg.minimum_saccade_duration))
    error('Invalid minimum saccade duration specified'); 
  end;
  
  n = size(pos, 1);
  
  % SG filter settings
  sg_span = ceil(cfg.minimum_saccade_duration * cfg.frequency); % Span of filter
  sg_order = 2;                                                 % Order of polynomial fit
  sg_win = 2 * ceil(sg_span) - 1;                               % Window length    
  
  [~, g] = sgolay(sg_order, sg_win);
       
  % Compute acceleration and velocity per component
  vel = nan(n, 3);
  acc = nan(n, 3);
    
  for idim = 1:2
    acc(:, idim) = filter(g(:, 3), 1, pos(:, idim));
    vel(:, idim) = filter(g(:, 2), 1, pos(:, idim));
    pos(:, idim) = filter(g(:, 1), 1, pos(:, idim));
            
    acc(1:sg_win, idim) = NaN;
    vel(1:sg_win, idim) = NaN;
    pos(1:sg_win, idim) = NaN;
  end
    
  % Shift to half window length to left
  pos = [pos(5:end, :); nan(4, size(pos, 2))];
  vel = [vel(5:end, :); nan(4, size(vel, 2))];
  acc = [acc(5:end, :); nan(4, size(acc, 2))];
  
  % Compute speed and acceleration
  vel(:, 3) = sqrt(sum(vel(:, 1:2), 2) .^ 2) * cfg.frequency;
  acc(:, 3) = sqrt(sum(acc(:, 1:2), 2) .^ 2) * cfg.frequency ^ 2;
