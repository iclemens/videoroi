classdef VideoROIDatasetView < EventProvider
%
% 
%
%  *--------------------* *------*
%  |                    | | Re   |
%  |    Composite       | | gi   |
%  |    Image + ROIs    | | on   | << Not sure about this
%  |                    | | s    | Maybe add some options
%  |                    | |      | and/or analysis tools
%  *--------------------* *------*
%  
%  *------------------------------*
%  |                              |
%  | Eye trace                    |
%  |                              |
%  *------------------------------*
%
%  Time control:
%  *-------------------------*
%  | Frames/stimuli          | Play
%  *-------------------------*-----*
%  | Trials                        |
%  *-------------------------------*
%
%
 
    methods(Access = public)
        function obj = VideoROIDatasetView()
            obj.setupGui();
        end
    end

    properties(Access = private)
        datasetName = 'Unknown';
        
        % Represents the virtual screen (i.e. what the participant saw)
        screenAxes = [];
        
        % Scrollbar used to control time
        timeSlider = [];
        timeLabel = [];
        
        % Starting an stopping of playback
        playPauseButton = [];
    end

    methods(Access = private)
        %
        %
        %
        function setupGui(obj)
            obj.screenAxes = GUIAxes();
            obj.screenAxes.addEventListener('construction', @(src) obj.onScreenAxesCreated(src));

            % Time control components
            obj.timeSlider = GUISlider();
            obj.timeSlider.addEventListener('change', @(x) obj.onTimeSliderChanged(x));
            
            obj.playPauseButton = GUIButton();
            obj.playPauseButton.addEventListener('click', @(src) obj.onPlayPauseButtonClicked(src));
            obj.playPauseButton.setLabel('Play');
           
            controlbar = GUIBoxArray();
            controlbar.setMargin([0 0 0 0]);
            controlbar.setHorizontalDistribution([NaN 25 25]);
            controlbar.addComponent(obj.timeSlider)            
            controlbar.addComponent(obj.playPauseButton);

            obj.timeLabel = GUILabel('Time x of y');

            horizontalSplit = GUIBoxArray();
            horizontalSplit.setHorizontalDistribution([NaN 150]);            
            horizontalSplit.addComponent(obj.screenAxes);
            horizontalSplit.addComponent(GUILabel('Placeholder'));

            % Put all components together
            verticalSplit = GUIBoxArray();
            verticalSplit.setVerticalDistribution([NaN 25 25]);
            verticalSplit.addComponent(horizontalSplit);
            verticalSplit.addComponent(obj.timeLabel);
            verticalSplit.addComponent(controlbar);

            mainWindow = GUIWindow();
            mainWindow.setTitle( sprintf('Dataset: %s', obj.datasetName) );

            mainWindow.addEventListener('keyPress', @(src, event) obj.onKeyPress(src, event));
            mainWindow.addEventListener('close', @(src) obj.onClose(src));
            mainWindow.addComponent(verticalSplit);
            
        end
        
        
        function onScreenAxesCreated(~, ~)
        end
        
        
        function onTimeSliderChanged(~, ~)
        end
        
        
        function onPlayPauseButtonClicked(~, ~)
        end
        
        
        function onKeyPress(~, ~, ~)
        end
        
        
        function onClose(~, ~)            
        end
    end
end
