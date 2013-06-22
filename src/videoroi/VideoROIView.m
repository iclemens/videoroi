classdef VideoROIView < EventProvider
        
    properties(Access = private)
        % GUI Components
        mainWindow;
        
        frameAxes;
        frameImage;
        frameSlider;
        frameLabel;                

        frameRect = {};
        frameRectCallbackID = {};
        
        roiList;
        sceneCheckbox;
        
        dataList;
        stimulusList;
        
        % Current frame state
        frameIndex;
        frameROIState;
        frameROIPosition;
        
        % Menu containing available tasks
        taskMenu;
        
        % True if the latest changes have not been saved
        unsavedFlag;
        
        % ROI Colors for listbox ...
        roiListColors = { ...
            '#000000', ...
            '#990000', '#009900', '#000099', ...
            '#999999', ...
            '#FF0000', '#00FF00', '#0000FF', ...           
            '#FF9900', '#FF0099', ...
            '#99FF00', '#00FF99', ...
            '#0099FF', '#9900FF', '#FF9999', ...
            '#FFFF00', '#FF00FF', ...
            '#00FFFF', ...
            };
        
        % ... and rectangles (will be computed later)
        roiRectColors = {};
        
        % Number of frames
        numberOfFrames;
                
        currentProjectPath = '';
    end
    
    methods(Access = public)
        
        %
        % Constructor for the VideoROIView
        %
        function obj = VideoROIView()
            obj.copyRectFromListColors()
            
            obj.setupGUI();                      

            obj.frameSlider.setValue(1);
            obj.frameSlider.setBounds(1, 2);
            
            obj.setupMenu();
        end


        %
        % Change the total number of frames in the loaded stimulus, this
        % causes the current frame to be reset to 1.
        %
        % @param frames Number of frames in the stimulus
        %
        function setNumberOfFrames(obj, frames)
            obj.numberOfFrames = frames;            
            obj.frameSlider.setValue(1);
            
            if(frames <= 1)
                obj.frameSlider.setBounds(0, 1);
            else
                obj.frameSlider.setBounds(1, frames);
            end;
            
            obj.setCurrentFrame(1);
        end
        
        
        %
        % Changes the currently displayed frame
        %
        % @param frame The frame that should be shown
        %
        function setCurrentFrame(obj, frame)
            obj.frameSlider.setValue(frame);
            obj.updateFrameLabel();
            
            obj.doFrameChange(frame);
        end


        %
        % Set flag that indicates whether the camera position
        % has changed
        %
        % @param value True if change, false otherwise
        %
        function setSceneChange(obj, value)
            obj.sceneCheckbox.setValue(value);
        end
        
        
        function setProjectDirectory(obj, projectDirectory)
            obj.currentProjectPath = projectDirectory;
        end
        
        
        %
        % Changes ROI information (state and position)
        %
        % @param states Whether or not the ROIs are enabled
        % @param positions The X/Y/W/H position of the rectangle        
        %
        function setROIInformation(obj, states, positions)
            obj.frameROIState = states;
            obj.frameROIPosition = positions;
        end

        
        %
        % Update list with regions of interest
        %
        % @param labels Cell array containing ROI names
        % @param states Whether or not the ROIs are enabled
        %
        function updateROIList(obj, labels, states)
            obj.roiList.clear();
            
            for i = 1:length(labels)
                if(states(i) == 0)
                    roiState = 'disabled';
                else
                    roiState = 'enabled';
                end                
                
                itemLabel = ['<html><b style="color:' ...
                    obj.roiListColors{i} ...
                    '">' labels{i} ' (' roiState ')' ...
                    '</b></html>'];
                                    
                obj.roiList.addItem(itemLabel);
            end          
        end

        
        %
        % Update list of datasets
        %
        % @param labels Cell array containing dataset names
        %
        function updateDatasetList(obj, labels)
            obj.dataList.clear();
            
            for i = 1:length(labels)
                obj.dataList.addItem(labels{i});
            end
        end
        
        
        %
        % Update list of stimuli
        %
        % @param labels Cell array containing stimulus names
        %
        function updateStimulusList(obj, labels)
            obj.stimulusList.clear();
            
            for i = 1:length(labels)
                obj.stimulusList.addItem(labels{i});
            end
        end
                       
        
        %
        % Updates all ROI rectangles in the current frame
        %
        % @param states Whether or not the ROIs are enabled
        % @param positions The X/Y/W/H position of the rectangle
        %
        function updateROIRects(obj, states, positions)            
            numROIs = size(states, 1);
            numRects = length(obj.frameRect);

            if(numRects < numROIs)
                for i = (numRects+1):numROIs                   
                    obj.frameRect{i} = 0;
                    obj.frameRectCallbackID{i} = 0;
                end                
            elseif (numRects > numROIs)
                for i = (numROIs+1:numRects)
                    if(obj.frameRect{i} ~= 0)
                        delete(obj.frameRect{i});
                    end                    
                end
                obj.frameRect(numROIs+1:numRects) = [];
                obj.frameRectCallbackID(numROIs+1:numRects) = [];
            end       
            
            for i = 1:numROIs
                state = states(i);
                position = squeeze(positions(i, :, :));

                % If the ROI is disabled, delete the rectangle
                if(state == 0)
                    if(obj.frameRect{i} ~= 0)
                        delete(obj.frameRect{i});
                        obj.frameRect{i} = 0;
                    end
                end

                % If the ROI is enabled, make sure the rectangle exists
                %  and set its position...
                if(state == 1)
                    if(obj.frameRect{i} == 0)
                        obj.createROIRect(i, position);
                    else
                        removeNewPositionCallback(obj.frameRect{i}, obj.frameRectCallbackID{i});
                        setConstrainedPosition(obj.frameRect{i}, position(:)');
                        obj.frameRectCallbackID{i} = addNewPositionCallback(obj.frameRect{i}, @(x) obj.onRectMoved(i));
                    end
                end
            end
        end                


        function updateTaskList(obj, taskList)
            % Update list of available tasks as used by the view.
            
            % Fixme: Clear existing entries
            
            for t = 1:length(taskList)
                uimenu(obj.taskMenu, 'Label', taskList(t).name, 'Callback', @(src, x) obj.onSetTask(taskList(t).name));
            end
        end
        
        
        %
        % Changes the image currently being shown
        %
        % @param img Matrix containing the image data
        %
        function swapImage(obj, img)
            h = get(obj.frameImage, 'Parent');
            
            oldXLim = get(h, 'XLim');
            oldYLim = get(h, 'YLim');
            
            % Change image
            set(obj.frameImage, 'XData', [1 size(img, 2)]);
            set(obj.frameImage, 'YData', [1 size(img, 1)]);
            set(obj.frameImage, 'CData', img);
            
            newXLim = [0.5 size(img, 2) + 0.5];
            newYLim = [0.5 size(img, 1) + 0.5];
            
            % Limits have changed, update 'em
            if( any(newXLim ~= oldXLim) || any(newYLim ~= oldYLim) )
                
                axis(h, 'equal');
                
                % Change limits on image            
                set(h, 'Xlim', newXLim);
                set(h, 'Ylim', newYLim);
            
                % Update constraints on ROI rectangles
                %numROIs = min(obj.engine.getNumberOfROIs(), length(obj.frameRect));
                fcn = makeConstrainToRectFcn('imrect', get(h, 'XLim'), get(h, 'YLim'));
                numROIs = length(obj.frameRect);
                for i = 1:numROIs
                    if(obj.frameRect{i} > 0)
                        setPositionConstraintFcn(obj.frameRect{i}, fcn);
                    end
                end
            end            
        end
        
        
        %
        % Display an error message
        %
        % @param message Message to display
        %
        function displayError(~, message)
            errordlg(message);
        end

        
    end

    
    methods(Access = protected)

        %%%%%%%%%%%%%%%%%%%%%%
        % Graphical interace %
        %%%%%%%%%%%%%%%%%%%%%%


        function setupGUI(obj)
            % Left part shows the stimulus
            obj.frameAxes = GUIAxes();
            obj.frameAxes.addEventListener('construction', @(x) obj.onFrameAxesCreated(x));

            % Frame slider at the bottom
            obj.frameSlider = GUISlider();
            obj.frameSlider.addEventListener('change', @(x) obj.onFrameSliderChanged(x));
            
            playButton = GUIButton();
            playButton.addEventListener('click', @(src) obj.onPlayButtonClicked(src));
            playButton.setLabel('Play');
            
            pauseButton = GUIButton();
            pauseButton.addEventListener('click', @(src) obj.onPauseButtonClicked(src));
            pauseButton.setLabel('Pause');
            
            controlbar = GUIBoxArray();
            controlbar.setMargin([0 0 0 0]);
            controlbar.setHorizontalDistribution([NaN 25 25]);
            controlbar.addComponent(obj.frameSlider)
            controlbar.addComponent(playButton);
            controlbar.addComponent(pauseButton);                        
            
            obj.frameLabel = GUILabel('Frame ? of #');
            
            horizontalSplit = GUIBoxArray();
            horizontalSplit.setHorizontalDistribution([NaN 150]);            
            horizontalSplit.addComponent(obj.frameAxes);
            horizontalSplit.addComponent(obj.setupTabPanel());

            % Put all components together
            verticalSplit = GUIBoxArray();
            verticalSplit.setVerticalDistribution([NaN 25 25]);
            verticalSplit.addComponent(horizontalSplit);
            verticalSplit.addComponent(obj.frameLabel);
            verticalSplit.addComponent(controlbar);

            obj.mainWindow = GUIWindow();
            obj.mainWindow.setTitle('VideoROI - Release 5');
            obj.mainWindow.addEventListener('keyPress', @(src, event) obj.onKeyPress(src, event));
            obj.mainWindow.addEventListener('close', @(src) obj.onClose(src));
            obj.mainWindow.addComponent(verticalSplit);
        end
        
        
        %
        % Setup tab-panel
        %
        function tabPanel = setupTabPanel(obj)
            tabPanel = GUITabPanel();
            tab1 = tabPanel.addTab('ROIs');
            tab1.addComponent(obj.setupStimulusPropertiesPane());
            tab2 = tabPanel.addTab('Project');
            tab2.addComponent(obj.setupProjectPane());
        end        

        
        %
        % Creates the ROI list and associated management buttons
        %
        function verticalSplit = setupStimulusPropertiesPane(obj)
            obj.roiList = GUIList();
            
            verticalSplit = GUIBoxArray();
            verticalSplit.setVerticalDistribution([30 NaN 30 30]);
                        
            verticalSplit.addComponent(GUILabel('Regions:'));
            verticalSplit.addComponent(obj.roiList);
            
            toggleButton = GUIButton();
            toggleButton.setLabel('Toggle ROI');
            toggleButton.addEventListener('click', @(src) obj.onToggleButtonClicked(src));
            
            %addButton = GUIButton();
            %addButton.setLabel('Add ROI');
            %addButton.addEventListener('click', @(src) obj.onAddButtonClicked(src));
            
            obj.sceneCheckbox = GUICheckbox();
            obj.sceneCheckbox.setLabel('Scene changed');
            obj.sceneCheckbox.addEventListener('click', @(src) obj.onSceneCheckboxClicked(src));
            
            verticalSplit.addComponent(toggleButton);
            %verticalSplit.addComponent(addButton);
            verticalSplit.addComponent(obj.sceneCheckbox);
        end


        %
        % Setup project pane
        %
        function verticalSplit = setupProjectPane(obj)
            obj.dataList = GUIList();
            obj.dataList.addEventListener('click', @(src) obj.onDatasetClicked(src));
            
            obj.stimulusList = GUIList();
            obj.stimulusList.addEventListener('click', @(src) obj.onStimulusClicked(src));

            verticalSplit = GUIBoxArray();
            verticalSplit.setVerticalDistribution([25 NaN 25 NaN]);

            verticalSplit.addComponent(GUILabel('Stimuli:'));
            verticalSplit.addComponent(obj.stimulusList);

            verticalSplit.addComponent(GUILabel('Datasets:'));
            verticalSplit.addComponent(obj.dataList);            
        end
        
        
        %
        % Creates the file-menu
        %        
        function setupMenu(obj)        
            h = uimenu('Label', '&File');
            uimenu(h, 'Label', '&New project...', 'Callback', @(src, x) obj.onNewProject(src));
            uimenu(h, 'Label', '&Open project...', 'Callback', @(src, x) obj.onOpenProject(src));
            uimenu(h, 'Label', '&Close project...', 'Callback', @(src, x) obj.onCloseProject(src));
            
            h = uimenu('Label', '&Project');
            uimenu(h, 'Label', 'Add &dataset...', 'Callback', @(src, x) obj.onAddDataset(src));
            uimenu(h, 'Label', 'Add &stimulus...', 'Callback', @(src, x) obj.onAddStimulus(src));
            obj.taskMenu = uimenu(h, 'Label',' Set &task');            
            
            h = uimenu('Label', '&Regions');
            uimenu(h, 'Label', '&Add ROI', 'Callback', @(src, x) obj.onAddButtonClicked(src));
            uimenu(h, 'Label', 'Force &Save', 'Callback', @(src, x) obj.onSave(src));
            uimenu(h, 'Label', '&Import', 'Separator', 'on', 'Callback', @(src, x) obj.onImportROI(src));
            uimenu(h, 'Label', '&Export', 'Callback', @(src, x) obj.onExportROI(src));
            
            h = uimenu('Label', '&Analysis');
            uimenu(h, 'Label', 'Perform ROI analysis...', 'Callback', @(src, x) obj.onPerformAnalysis(src));
        end;
        
        
        
        %
        % Copy list colors into rectangle colors
        %
        function copyRectFromListColors(obj)
            for i = 1:length(obj.roiListColors)
                color = [ ...
                    hex2dec(obj.roiListColors{i}(2:3)), ...
                    hex2dec(obj.roiListColors{i}(4:5)), ...
                    hex2dec(obj.roiListColors{i}(6:7))];
                
                obj.roiRectColors{i} = color/255;
            end
        end
        
        
        %
        % Creates a new ROI rectangle
        %
        % @param i - Index of the ROI rectangle
        % @param position - Initial position of the rectangle
        %
        function createROIRect(obj, i, position)
            if(obj.frameRect{i} > 0)
                delete(obj.frameRect{i});
            end
            
            obj.frameRect{i} = imrect(get(obj.frameImage, 'Parent') , position(:)');

            xl = get(get(obj.frameImage, 'Parent'), 'XLim');
            yl = get(get(obj.frameImage, 'Parent'), 'YLim');
            
            fcn = makeConstrainToRectFcn('imrect', xl, yl);
            setPositionConstraintFcn(obj.frameRect{i}, fcn);            
            
            setColor(obj.frameRect{i}, obj.roiRectColors{i});
            obj.frameRectCallbackID{i} = addNewPositionCallback(obj.frameRect{i}, @(x) obj.onRectMoved(i));
            
        end            

    
        %
        % Internal function invoked when the current frame
        % has been changed. It will set an internal variable
        % and call methods waiting for the "frameChange" event.
        %
        % @param index The new frame index
        %
        function doFrameChange(obj, index)
            obj.frameIndex = index;
            obj.invokeEventListeners('frameChange', index);
            drawnow;
        end
                       
        
        %
        % Update the label shown above the frame selection slider
        %
        function updateFrameLabel(obj)
            obj.frameLabel.setLabel(['Frame ' num2str(obj.frameSlider.getValue()) ...
                ' of ' num2str(obj.numberOfFrames)]);
        end        
        
        
        % %%%%%%%%%%%%%% %
        % EVENT HANDLERS %
        % %%%%%%%%%%%%%% %
        
        
        %
        % Function called when the frame axes have been created
        % It initilizes a test-pattern an configures the axes
        %
        % @param src Newly created GUIAxes object
        %
        function onFrameAxesCreated(obj, src)
            h = src.getHandle();            
            
            I = ones(1024, 768, 3);
            obj.frameImage = image(I, 'Parent', h);
            
            set(h, 'XTick', []);
            set(h, 'YTick', []);
        end        
        

        %
        % Function called when a project is to be created
        %
        function onNewProject(obj, ~)
            projectDirectory = uigetdir ('', 'Choose project directory');
            
            if(projectDirectory ~= 0)
                obj.invokeEventListeners('newProject', projectDirectory);
                obj.currentProjectPath = projectDirectory;
            end
        end

        
        %
        % Function called when a project is to be opened
        %        
        function onOpenProject(obj, ~)
            projectDirectory = uigetdir('', 'Choose project directory');
            
            if(projectDirectory ~= 0)
                obj.invokeEventListeners('openProject', projectDirectory);
                obj.currentProjectPath = projectDirectory;
            end
        end
        
        
        %
        % Function called when a project is to be closed
        %        
        function onCloseProject(obj, ~)
            obj.invokeEventListeners('closeProject');
            obj.currentProjectPath = '';
        end        
        
        
        
        function onSetTask(obj, taskName)
            % Function to be called when a task is selected
            
            obj.invokeEventListeners('setTask', taskName);
        end
        
        
        %
        % Function called when adding a stimulus to the project
        %
        function onAddStimulus(obj, ~)
            if(obj.currentProjectPath ~= 0)
                
                fileTypes = {'*.wmv', 'Video files'; '*.jpg', 'Image files'};
                
                [filename, pathname] = uigetfile(fileTypes, 'Add stimulus');
            
                if(filename ~= 0)
                    filename = fullfile(pathname, filename);
                    obj.invokeEventListeners('addStimulus', filename);
                end
            else
                warndlg('No active project, unable to add stimulus.');
            end
        end


        %
        % Function called when a stimulus has been selected
        %
        function onStimulusClicked(obj, src)
            if(obj.unsavedFlag)
                choice = questdlg('Save changes before loading stimulus?', ...
                    'Save changed', 'Yes', 'No', 'Yes');

                if(strcmp(choice, 'Yes'))
                    obj.invokeEventListeners('saveROIFile');
                end
            end
            
            index = src.getSelectedIndex();
            obj.invokeEventListeners('changeStimulus', index);
            obj.unsavedFlag = 0;
        end


        %
        % Function called when the window is being closed
        %
        function onClose(obj, ~)
            if(obj.unsavedFlag)
                choice = questdlg('Save changes before loading stimulus?', ...
                    'Save changed', 'Yes', 'No', 'Yes');

                if(strcmp(choice, 'Yes'))
                    obj.invokeEventListeners('saveROIFile');
                end
            end
        end
        

        %
        % Function called when adding a dataset to the project
        %        
        function onAddDataset(obj, ~)
            if(obj.currentProjectPath ~= 0)                
                [filename, pathname] = uigetfile({'*.txt', 'Datasets'}, 'Add dataset');
            
                if(filename ~= 0)
                    filename = fullfile(pathname, filename);
                    obj.invokeEventListeners('addDataset', filename);
                end
            else
                warndlg('No active project, unable to add dataset');
            end            
        end
        
                 
        function onPlayButtonClicked(obj, ~)
            obj.invokeEventListeners('playVideo');
        end
        
        
        function onPauseButtonClicked(obj, ~)
            obj.invokeEventListeners('pauseVideo');
        end
        
        
        %
        % Function called when a dataset has been selected
        %
        function onDatasetClicked(obj, src)
            index = src.getSelectedIndex();
            obj.invokeEventListeners('changeDataset', index);
        end
        

        %
        % Function called when "save" has been selected. If save
        % the ROIs under a new file in the project directory.
        %
        function onSave(obj, ~)
            obj.invokeEventListeners('saveROIFile');
        end
        

        %
        % Function called when "import" has been selected. It shows
        % a file-selection dialog and will invoke a callback
        % once a valid file has been selected.
        %
        function onImportROI(obj, ~)
            [filename, pathname] = uigetfile({'*.roi', 'ROI Files'}, 'Import ROIs');
            
            if(filename ~= 0)
                filename = fullfile(pathname, filename);
                obj.invokeEventListeners('importROIFile', filename);
                obj.unsavedFlag = 1;
            end
        end
        
        
        %
        % Function called when "export" has been selected. It will show
        % a dialog and invoke a callback once a valid file-name has been
        % selected.
        %
        function onExportROI(obj, ~)
            [filename, pathname] = uiputfile({'*.roi', 'ROI Files'}, 'Save ROIs As');
            
            if(filename ~= 0)
                filename = fullfile(pathname, filename);
                obj.invokeEventListeners('exportROIFile', filename);
            end
        end
        
        
        %
        % Function called when the "toggle ROI" button has been clicked.
        % It will invoke a callback and pass the selected ROI as an
        % argument.
        %
        function onToggleButtonClicked(obj, ~)
            obj.invokeEventListeners('toggleROI', obj.roiList.getSelectedIndex());
            obj.unsavedFlag = 1;
        end
        
        
        %
        % Function called when the "add ROI" button has been clicked.
        % It will ask for the name of the new ROI and invoke a callback.
        %
        function onAddButtonClicked(obj, ~)
            roiName = inputdlg('Enter name for ROI:', 'Add new ROI', 1);
            
            if ~isempty(roiName)
                obj.invokeEventListeners('newROI', roiName{1}, obj.frameIndex);
                obj.unsavedFlag = 1;
            end
        end

        
        function onPerformAnalysis(obj, ~)
            filename = uiputfile('*.csv', 'Choose output location');            
            if(isempty(filename)), return; end;            
            
            obj.invokeEventListeners('performAnalysis', filename);
        end
        

        function onSceneCheckboxClicked(obj, ~)
            obj.invokeEventListeners('sceneChanged', obj.frameIndex, obj.sceneCheckbox.getValue());
            obj.unsavedFlag = 1;
        end
        
        function onKeyPress(obj, ~, event)
            if(strcmp(event.Key, 'leftarrow'))
                newValue = obj.frameSlider.getValue() - 1;
                
                if(newValue > 0)
                    obj.frameSlider.setValue(newValue);
                    obj.onFrameSliderChanged(obj.frameSlider);
                end
            end

            if(strcmp(event.Key, 'rightarrow'))
                newValue = obj.frameSlider.getValue() + 1;
                
                if(newValue <= obj.numberOfFrames)
                    obj.frameSlider.setValue(newValue);
                    obj.onFrameSliderChanged(obj.frameSlider);
                end;                               
            end           
        end

        
        %
        % Function called when the frame slider has been moved.
        % It will compute the new frame index and notifies the
        % controller about it.
        %
        % @param src GUISlider instance
        %
        function onFrameSliderChanged(obj, src)
            frame = src.getValue();
            
            if ~isinteger(frame)
                frame = floor(src.getValue());                
                if(frame < 1), frame = 1; end;                
                src.setValue(frame);
            end
            
            obj.updateFrameLabel();
            obj.doFrameChange(frame);
        end                      

        
        function onRectMoved(obj, roi)
            position = getPosition(obj.frameRect{roi});
            obj.invokeEventListeners('moveROI', roi, position);
            obj.unsavedFlag = 1;
        end        
        
    end        
    
end