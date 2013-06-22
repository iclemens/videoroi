classdef VideoROIGaze < handle
   
    properties
        % Screen distance, dimensions and resolution
        screen;
        
        % Header from eye-tracker data
        header;
        
        % Eye-tracker data and derived values
        data;
    end
    
    methods(Access = public)
        function obj = VideoROIGaze()
            % No dataset has been loaded
            obj.header = NaN;
            obj.data = NaN;
            
            % Default screen settings
            scr = [];
            scr.distance = 500;
            scr.resolution = [1024 768];
            scr.dimensions = [403 305];

            obj.defineScreen(scr);
        end

        % Set screen properties        
        function defineScreen(obj, screen)
            obj.screen = screen;
            obj.updateGazeCoordinates();
        end
               
        % Load data for one participant
        function loadDataset(obj, datasetDirectory, filename)
            %[s, m, obj.header] = read_idf(filename);
            %obj.data = idf_split_trials(s, m);
            %obj.data = idf_parse_frame_msgs(obj.data);

            %obj.updateGazeCoordinates();
        end
        
        % Saccade detection
        function annotateTrace(obj)
            % Threshold in degrees per second
            saccade_threshold = degtorad(45);
            
            col_gaze = idf_find_columns({'R Gaze X [rad]', 'R Gaze Y [rad]'}, obj.header);
            
            for t = 1:length(obj.data)
                delta_t = diff(obj.data(t).samples(1:2, 1)) * 1e-6;
                delta_s = diff(obj.data(t).samples(:, col_gaze));
                
                % Eye velocity (vector) in radians per second
                dsdt = delta_s ./ delta_t;                
                speed = sqrt(sum(dsdt .^ 2, 2));
                
                saccade_mask = ...
                    ([0; speed] > saccade_threshold) | ...
                    ([speed; 0] > saccade_threshold);

                % We might want to extend the masks to see where
                %  saccades began
                
                % Store saccades
                obj.data(t).saccade_mask = saccade_mask;
            end
        end        
    end
    
    methods(Access = private)
        % Update gaze coordinates given screen information
        function updateGazeCoordinates(obj)
            if(~isstruct(obj.data)), return; end;
            
            cfg = [];
            cfg.src = {'R POR X [px]', 'R POR Y [px]'};
            cfg.dest = {'R Gaze X [rad]', 'R Gaze Y [rad]'};
            
            cfg.procfcn = @(cfg, src) [ ...
                atan2(obj.screen.distance, (src(:, 1) ./ obj.screen.resolution(1) - 0.5) .* obj.screen.dimensions(1)) - 0.5 * pi, ...
                atan2(obj.screen.distance, (src(:, 2) ./ obj.screen.resolution(2) - 0.5) .* obj.screen.dimensions(2)) - 0.5 * pi];
            
            [obj.data, obj.header] = idf_transform_data(cfg, obj.data, obj.header);                       
        end        
    end
end