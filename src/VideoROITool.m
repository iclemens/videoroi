function VideoROITool(projectDir)
% VIDEOROITOOL allows one to define regions-of-interest
%  in movie frames.

vr_initialize();

if(nargin == 0)
    projectDir = uigetdir('', 'Open project directory');
     
    if(isempty(projectDir))
        error('Please choose a project directory first');
    end    
end

roiTool = VideoROI();
roiTool.openProject(projectDir);
