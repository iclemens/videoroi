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
% All data for the entire trial will be loaded, but the
% XLimits will only contain 50ms (about 3 frames).
% The image will show the frame corresponding to the first
% sample shown in the eye-trace.
%
% It should be possible to scroll to the last sample! That
% means almost the entire trace window will be blank.
%
% The slider will jump to the first sample of the frame.
%
 
    methods(Access = public)
        function obj = VideoROIDatasetView()
            obj.screenResolution = [1024 768];
            obj.setupGui();
        end


        %
        % Sets resolution of screen.
        %
        function setResolution(obj, screenResolution)
            obj.screenResolution = screenResolution;
            
            I = ones(obj.screenResolution(1), obj.screenResolution(2), 3);
            set(obj.screenImage, 'CData', I);
            set(obj.screenImage, 'XData', [1 obj.screenResolution(2)]);
            set(obj.screenImage, 'XData', [1 obj.screenResolution(1)]);
        end


        %
        % Sets the number of the trial currently displayed.
        %
        function setCurrentTrial(obj, currentTrial)
            if obj.currentTrial ~= currentTrial
                obj.currentTrial = currentTrial;
                
                if obj.trialSlider.getValue() ~= currentTrial
                    obj.trialSlider.setValue(currentTrial)
                end
            end
            
            obj.updateLabels();
        end


        %
        % Set the total number of available trials.
        %
        function setNumberOfTrials(obj, numberOfTrials)
            obj.numberOfTrials = numberOfTrials;
            obj.trialSlider.setBounds(1, obj.numberOfTrials);
            obj.updateLabels();
        end
    end

    properties(Access = private)
        datasetName = 'Unknown';
        
        % Represents the virtual screen (i.e. what the participant saw)
        screenResolution = [];
        screenAxes = [];
        screenImage = [];
        
        % Used to draw eye trace
        traceAxes = [];

        % Trial counts
        currentTrial = NaN;
        numberOfTrials = 1;        
        
        % Scrollbar used to control time and trial
        trialSlider = [];
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
            obj.screenAxes.setMargin([0 0 0 0]);
            obj.screenAxes.addEventListener('construction', @(src) obj.onScreenAxesCreated(src));

            obj.traceAxes = GUIAxes();
            obj.traceAxes.setMargin([0 0 0 0]);
            obj.traceAxes.addEventListener('construction', @(src) obj.onTraceAxesCreated(src));
            
            % Time control components
            obj.timeSlider = GUISlider();   % FIXME: Frames or seconds?!
            obj.timeSlider.addEventListener('change', @(x) obj.onTimeSliderChanged(x));
            obj.trialSlider = GUISlider();
            obj.trialSlider.addEventListener('change', @(src) obj.onTrialSliderChanged(src));
            
            obj.playPauseButton = GUIButton();
            obj.playPauseButton.addEventListener('click', @(src) obj.onPlayPauseButtonClicked(src));
            obj.playPauseButton.setLabel('Play');
           
            controlbar = GUIBoxArray();
            controlbar.setMargin([0 0 0 0]);
            controlbar.setHorizontalDistribution([NaN NaN 25]);
            controlbar.addComponent(obj.timeSlider);
            controlbar.addComponent(obj.trialSlider);
            controlbar.addComponent(obj.playPauseButton);

            obj.timeLabel = GUILabel('Time {} of {}sec / Trial {} of {}');

            horizontalSplit = GUIBoxArray();
            horizontalSplit.setHorizontalDistribution([NaN 150]);            
            horizontalSplit.addComponent(obj.screenAxes);
            horizontalSplit.addComponent(GUILabel('Placeholder'));

            % Put all components together
            verticalSplit = GUIBoxArray();
            verticalSplit.setMargin([0 0 0 0]);
            verticalSplit.setVerticalDistribution([NaN 200 25 25]);
            verticalSplit.addComponent(horizontalSplit);
            verticalSplit.addComponent(obj.traceAxes);
            verticalSplit.addComponent(obj.timeLabel);
            verticalSplit.addComponent(controlbar);

            mainWindow = GUIWindow();
            mainWindow.setTitle( sprintf('Dataset: %s', obj.datasetName) );

            mainWindow.addEventListener('keyPress', @(src, event) obj.onKeyPress(src, event));
            mainWindow.addEventListener('close', @(src) obj.onClose(src));
            mainWindow.addComponent(verticalSplit);
        end
        
        
        %
        % Update labels
        %
        function updateLabels(obj)
            obj.timeLabel.setLabel(sprintf( ...
                'Time %.2f of %.2f sec / Trial %d of %d', ...
                0, 0, obj.currentTrial, obj.numberOfTrials));
        end
        

        %
        % Create a new image to show in the screen axes.
        %
        function onScreenAxesCreated(obj, src)
            h = src.getHandle();

            I = ones(obj.screenResolution(1), obj.screenResolution(2), 3);
            obj.screenImage = image(I, 'Parent', h);

            set(h, 'XTick', []);
            set(h, 'YTick', []);            
        end


        %
        % Setup trace axes.
        %
        function onTraceAxesCreated(~, src)
            h = src.getHandle();
            t = linspace(0, 10, 20);
            plot(h, t, sin(t));
        end
        
        
        function onTrialSliderChanged(obj, src)
            value = round(src.getValue());
            obj.invokeEventListeners('changeTrial', value);
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
