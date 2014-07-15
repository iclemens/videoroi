function screen = compose_screen(project, stimuli, resolution, time)
% Tries to reproduce screen contents based on array of stimuli

    if nargin < 2, resolution = [1024, 768]; end;
    if nargin < 3, time = 1500; end;

    screen = 256 * ones(resolution(2), resolution(1), 3);
    
    for i_st = 1:numel(stimuli)        
        if time < stimuli(i_st).onset || time > stimuli(i_st).offset, continue; end;
        
        % Determine stimulus filename
        [~, filename, ~] = fileparts(stimuli(i_st).name);
        stim_info = project.getInfoForStimulus(filename);        
        filename = fullfile(stim_info.resourcepath, stim_info.filename);
        
        % Load fame
        stimulus = VideoROIStimulus();
        stimulus.openStimulus(filename);
        frame = stimulus.readFrame(stimuli(i_st).frame);
        
        image(frame);
        
        screen = place_image(screen, frame, stimuli(i_st).position);
    end
    
    
    function im = place_image(im, si, pos)    
        tmp = imresize(si, pos([4 3]));
        im(pos(2) + (1:pos(4)), pos(1) + (1:pos(3)), :) = tmp;
    end
end
