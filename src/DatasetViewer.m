function DatasetViewer(cfg)
     
    if nargin < 1, cfg = struct; end;
    
    vr_initialize();
    cfg = vr_checkconfig(cfg, 'defaults', {'projectdirectory', '/Users/ivar/Documents/103Creek'});

    project = VideoROIProject(cfg.projectdirectory);    
    numDatasets = project.getNumberOfDatasets();
        
    datasetInfo = project.getInfoForDataset(1);    
    dataset = VideoROIDataset(datasetInfo, 'Task4Logic');

    [data, columns] = dataset.getAnnotationsForTrial(3, 'radians');
    data(:, 1) = (data(:, 1) - data(1, 1)) / 1e6;

    
    cfg = [];
    cfg.frequency = 1 / (data(2, 1) - data(1, 1));
    [pos, vel, acc] = ed_filter(cfg, data(:, 2:3));
    
    
    figure(1); clf;
    
    h = nan(3, 1);    
    for i = 1:3
        h(i) = subplot(3, 1, i);
        hold on;
        xlabel('Time (seconds)');
    end;    
    linkaxes(h, 'x');
    
    axes(h(1));
    title('Horizontal Eye Position (pixels)');    
    plot(data(:, 1), data(:, 2), 'b');
    plot(data(:, 1), pos(:, 1), 'b--');
    
    
    axes(h(2));
    title('Vertical Eye Position (pixels)');    
    plot(data(:, 1), data(:, 3), 'b');
    plot(data(:, 1), pos(:, 2), 'b--');
   
    axes(h(3));    
    dH = gradient(data(:, 2)) ./ gradient(data(:, 1));
    dV = gradient(data(:, 3)) ./ gradient(data(:, 1));
    velocity = sqrt(dH .^ 2 + dV .^ 2);
    
    plot(data(:, 1), velocity, 'b');
    plot(data(:, 1), vel(:, 3), 'b--');
    
    % Cluster and plot saccade and fixation intervals
    pos (data(:, 4) == 0, :) = NaN;
    vel( data(:, 4) == 0, :) = NaN;
    
    axes(h(1));
    plot(data(:, 1), pos(:, 1), 'r', 'LineWidth', 2);
    pan xon;
    
    axes(h(2));
    plot(data(:, 1), pos(:, 2), 'r', 'LineWidth', 2);
    pan xon;
    
    axes(h(3));
    plot(data(:, 1), vel(:, 3), 'r', 'LineWidth', 2);
    pan xon;
end
