function [output, regionlabels] = vr_assignregions(cfg, data)
% VR_ASSIGNREGIONS  Assign region of interest to every sample.
%
%   cfg.project  Project.
%   cfg.stimuli  Cell-array containing list of stimuli per trial.
%   cfg.ignoreafterscenechange  Amount of time (in seconds) to ignore after a scene has changed.
%   cfg.minimumfixationduration  Minimum duration (in seconds) of a fixation.
%

    vr_checkconfig(cfg, 'required', 'project');
    vr_checkconfig(cfg, 'required', 'stimuli');
    cfg = vr_checkconfig(cfg, 'defaults', {'ignoreafterscenechange', 0.15});
    cfg = vr_checkconfig(cfg, 'defaults', {'minimumfixationduration', 0.10});

    % Initialize output structure
    output = [];
    output.cfg = cfg;
    if(isfield(data, 'cfg')), output.cfg.previous = data.cfg; end;
    output.labels = {data.labels{:}, 'frame_nr', 'stimulus_nr', 'roi_nr', 'overlap', 'ignore_flag'};

    output.time = data.time;
    
    ntrials = length(data.trials);
    output.trials = cell(1, ntrials);
    for i = 1:ntrials
        output.trials{i} = [data.trials{i}, zeros(size(data.trials{i}, 1), 5)];
    end;

    % Get column indices
    col_fixation_mask = strcmp(output.labels, 'fixation_mask');
    
    col_px = strcmp(output.labels, 'px');
    col_py = strcmp(output.labels, 'py');
    col_frame_nr = strcmp(output.labels, 'frame_nr');
    col_stimulus_nr = strcmp(output.labels, 'stimulus_nr');
    col_roi_nr = strcmp(output.labels, 'roi_nr');
    col_overlap = strcmp(output.labels, 'overlap');
    col_ignore_flag = strcmp(output.labels, 'ignore_flag');
        
    % We also return region labels, even though that is
    % not strictly our responsibility.
    regionlabels = cell(1, ntrials);    
    skipped_stimuli = {};
    
    for t = 1:ntrials
        regionlabels{t} = cell(1, length(cfg.stimuli{t}));
        
        for s = 1:length(cfg.stimuli{t})
            stimulus_info = get_stimulus_info(cfg.project, cfg.stimuli{t}(s).name);

            % Display warning if a stimulus is not being analyzed.
            if(~isstruct(stimulus_info))
                if(~any(strcmp(skipped_stimuli, cfg.stimuli{t}(s).name)))
                    disp(['Warning: Skipping stimulus: ' cfg.stimuli{t}(s).name]);
                    skipped_stimuli{end + 1} = cfg.stimuli{t}(s).name;
                end;
                continue;
            end;

            frame = cfg.stimuli{t}(s).frame;
            if(frame == 0), continue; end;

            % Samples that belong to stimulus
            sample_slc = cfg.stimuli{t}(s).onset:cfg.stimuli{t}(s).offset;

            % Load regions of interest
            region_filename = cfg.project.getLatestROIFilename(stimulus_info);
            regions = VideoROIRegions(stimulus_info);

            if(isempty(region_filename))
                disp(['Warning: No ROIs defined for stimulus ' stimulus_info.name]);
                break;
            end

            if(~exist(region_filename, 'file'))
                disp(['Warning: File ' region_filename ' does not exist']);
                break;
            end

            regions.loadRegionsFromFile(region_filename);

            % Get ROI data
            [roiState, roiPosition, sceneChange] = regions.getFrameInfo(frame);
            roiPosition(:, :, [1 3]) = roiPosition(:, :, [1 3]) ./ 640 .* 1024;
            roiPosition(:, :, [2 4]) = roiPosition(:, :, [2 4]) ./ 640 .* 1024;

            regionlabels{t}{s} = cell(1, length(roiState));


            % Add stimulus number to samples
            output.trials{t}(sample_slc, col_stimulus_nr) = s;
            output.trials{t}(sample_slc, col_frame_nr) = cfg.stimuli{t}(s).frame;

            % Assign ROIs to samples
            for r = 1:length(roiState)
                % Disabled, skip this region
                if(~roiState(r)), continue; end;

                % Compute region corners
                position = squeeze(roiPosition(r, :));
                xr = position(1) + [0 position(3)];
                yr = position(2) + [0 position(4)];

                % Compute fixation corners
                pixels_per_degree = 22;
                box_size = 1 * pixels_per_degree;   % in Pixels
                
                xs = [output.trials{t}(sample_slc, col_px) - box_size / 2, ...
                      output.trials{t}(sample_slc, col_px) + box_size / 2];
                  
                ys = [output.trials{t}(sample_slc, col_py) - box_size / 2, ...
                      output.trials{t}(sample_slc, col_py) + box_size / 2];

                % Compute overlap between fixation box and region box
                xoverlap = max( min(xs(:, 2), xr(2)) - max(xs(:, 1), xr(1)), 0) / box_size;
                yoverlap = max( min(ys(:, 2), yr(2)) - max(ys(:, 1), yr(1)), 0) / box_size;
                overlap = (xoverlap .* yoverlap);

                if(any(overlap < 0.0) || any(overlap > 1.0 + 1e-10))
                    error('Error, overlap between region and fixation box is out of bounds.');
                end;

                % Only update if this region has larger overlap than
                %  possible previous match.
                update = overlap > output.trials{t}(sample_slc, col_overlap);
                output.trials{t}(sample_slc(update), col_roi_nr) = r;
                output.trials{t}(sample_slc(update), col_overlap) = overlap(update);

                regionlabels{t}{s}{r} = regions.getLabelForRegion(r);
            end;

            % Mark samples to be ignored
            if(sceneChange)
                time = (output.time{t} - output.time{t}(sample_slc(1))) / 1000 / 1000;
                output.trials{t}(time >= 0 & time < cfg.ignoreafterscenechange, col_ignore_flag) = 1;
            end
        end;
        
        % Clear fixation mask on marked samples
        output.trials{t}(output.trials{t}(:, col_ignore_flag) == 1, [col_fixation_mask col_roi_nr col_overlap]) = 0; 
    end;
    
    
    function stimulus_info = get_stimulus_info(project, name)
    % GET_STIMULUS_INFO  Find and return information about the 
    % stimulus with name [name] in the specified project.

        persistent cache;        
        if(~iscell(cache)), cache = cell(0, 2); end;
        
        if(size(cache, 1) > 0)            
            cache_index = strcmp(cache(:, 1), name);
            stimulus_info = cache(cache_index, 2);
            if(~isempty(stimulus_info)), return; end;
        end;
    
        n_stimuli = project.getNumberOfStimuli();
        [~, oname, ~] = fileparts(name);

        for i_stimulus = 1:n_stimuli
            stimulus_info = project.getInfoForStimulus(i_stimulus);
            [~, sname, ~] = fileparts(stimulus_info.name);
                        
            sz = min(length(sname), length(oname));            
            if(sz < 1), continue; end;
            
            if strncmpi(sname, oname, sz)
                cache{end + 1, 1} = name;
                cache{end, 2} = stimulus_info;
                return;
            end
        end
    
        cache{end + 1, 1} = name;
        cache{end, 2} = 0;
        stimulus_info = 0;
    end    
end
