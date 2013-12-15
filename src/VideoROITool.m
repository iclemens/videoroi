function VideoROITool(projectDir)
% VIDEOROITOOL Define regions-of-interest in both movie frames
% as well as images.
%
% VideoRoiTool(projectDir) uses projectDir instead of asking
% for a project direcotry on startup.
% 

    vr_initialize();

    if(nargin == 0)
        projectDir = uigetdir('', 'Open project directory');

        if(isempty(projectDir))
            error('Please choose a project directory first');
        end    
    end

    roiTool = VideoROIProjectController();
    roiTool.onOpenProject([], projectDir);
