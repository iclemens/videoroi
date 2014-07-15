%% Prepare images containing screen contents

if ~exist('screens', 'dir'), mkdir('screens'); end;

time = 1500;
project = VideoROIProject('/Users/ivar/Documents/Taak 1 def input/');
task = project.getTaskName();
n = project.getNumberOfDatasets();

ds_info = project.getInfoForDataset(1);
dataset = VideoROIDataset(ds_info, task);
resolution = dataset.getScreenResolution();

m = dataset.getNumberOfTrials();
trial_descrs = cell(1, m);
for i_tr = 1:m
    descr = dataset.getDescriptionForTrial(i_tr);
    if numel(descr) == 0, continue; end;
    
    disp(['Generating screen for trial ' num2str(i_tr) '/' num2str(m)]);
    trial_descrs{i_tr} = descr;
    stimuli = dataset.getStimuliForTrial(i_tr);
    screen = compose_screen(project, stimuli, resolution, time);
    image(1/256*screen);shg;drawnow;
    imwrite(1/256*screen, sprintf('screens/%s.png', descr));
end

close all;
save('trials', 'trial_descrs');
save('screen', 'resolution');


%% Count fixations for each pixel

if ~exist('fixmaps', 'dir'), mkdir('fixmaps'); end;
load('trials');
load('screen');

project = VideoROIProject('/Users/ivar/Documents/Taak 1 def input/');
task = project.getTaskName();
n = project.getNumberOfDatasets();

fixmap = cell(1, numel(trial_descrs));
for i_tr = 1:numel(trial_descrs)
    fixmap{i_tr} = zeros(resolution(2), resolution(1));
end

for i_ds = 1:n
    disp(['Dataset ' num2str(i_ds)]);
    
    ds_info = project.getInfoForDataset(i_ds);
    dataset = VideoROIDataset(ds_info, task);
    
    m = dataset.getNumberOfTrials();
    
    for i_tr = 1:m
        descr = dataset.getDescriptionForTrial(i_tr);
        if numel(descr) == 0, continue; end;
        
        % Find global trial index
        i_gtr = find(strcmp(descr, trial_descrs));
        if numel(i_gtr) ~= 1, continue; end;
        
        disp([' Trial ' num2str(i_tr)]);
        gaze_data = dataset.getAnnotationsForTrial(i_tr);
        tmp = round(gaze_data(gaze_data(:, 4) == 1, 2:3));
        for i = 1:size(tmp, 1)
            x = tmp(i, 1);
            y = tmp(i, 2);
            
            if x < 1 || y < 1, continue; end;
            if x > resolution(1) || y > resolution(2), continue; end;
            
            fixmap{i_gtr}(y, x) = fixmap{i_gtr}(y, x) + 1;
        end
    end
end

for i_tr = 1:numel(trial_descrs)
    fixation_map = fixmap{i_tr};
    save(sprintf('fixmaps/%s.mat', trial_descrs{i_tr}), 'fixation_map');
end


%% Combine heatmap and screen image

if ~exist('heatmaps', 'dir'), mkdir('heatmaps'); end;
blend_img = @(a, b) 1 - (1 - 0.95*a) .* (1 - b);
load('trials');

for i_tr = 1:numel(trial_descrs)
    
    trial = trial_descrs{i_tr};
    if numel(trial) == 0, continue; end;
    
    screen = imread(['screens/' trial '.png']);
    load(['fixmaps/' trial '.mat']);
    
    % Create colormap that starts at white as opposed to blue
    cmap = jet(); cmap(1:16,3) = linspace(0, 1, 16);
    
    % Blur fixation map
    blur_filter = fspecial('gaussian',[20 20], 4);
    fixmap_flt = imfilter(fixation_map, blur_filter, 'replicate');
    
    % Use exponential scale
    fixmap_flt = 1.15 .^ fixmap_flt;
    
    % Convert to RGB
    fixmap_scl = round(1 + (fixmap_flt - min(fixmap_flt(:))) ./ (max(fixmap_flt(:)) - min(fixmap_flt(:))) * 255);
    fixmap_rgb = ind2rgb(fixmap_scl, cmap);
    
    % Blend with screen
    tmp = blend_img(double(screen)/256, fixmap_rgb);
    
    % Write to file and display
    imwrite(tmp, ['heatmaps/' trial '.png']);
    image(tmp); shg; axis equal;
    
end;