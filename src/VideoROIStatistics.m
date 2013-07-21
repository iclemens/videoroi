function VideoROIStatistics(cfg)
%
% Collects statistics about the regions of interest in each video/stimulus.
%
%  Per dataset per trial:
%   total time in roi
%   total fixation time
%   total roi area (pixels x frames)
%   total roi display time / roi are
%   total trial duration
%

    vr_initialize();
    cfg = vr_checkconfig(cfg, 'defaults', {'projectdirectory', @(x) uigetdir('', 'Open project directory')});    
    cfg = vr_checkconfig(cfg, 'validate', {'projectdirectory', @(v) ~isempty(v) && ischar(v) && exist(v, 'dir') == 7});
    cfg = vr_checkconfig(cfg, 'defaults', {'outputfile', fullfile(cfg.projectdirectory, 'statistics.csv')});   

    
    
end