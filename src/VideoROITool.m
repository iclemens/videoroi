function VideoROITool(projectDir)
% VIDEOROITOOL allows one to define regions-of-interest
%  in movie frames.

% Determine directory wheter m-file is located
path = fileparts(mfilename('fullpath'));

% Add source directories to path
warning off;
addpath(path);
addpath(fullfile(path, 'idf'));
addpath(fullfile(path, 'gui'));
addpath(fullfile(path, 'gui/controls'));
addpath(fullfile(path, 'videoroi'));
warning on;

if(nargin == 0)
    projectDir = uigetdir('', 'Open project directory');
     
    if(isempty(projectDir))
        error('Please choose a project directory first');
    end    
end

roiTool = VideoROI();
roiTool.openProject(projectDir);
