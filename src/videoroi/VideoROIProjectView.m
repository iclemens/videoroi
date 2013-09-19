classdef VideoROIProjectView < EventProvider
%
% Project explorer interface
%
%  Shows a list of stimuli and datasets.
%  Manages project settings
%
    
    %obj.invokeEventListeners('openProject', projectDirectory);

    methods(Access = public)
        function obj = VideoROIProjectView()
            obj.setupGUI();            
        end


        %
        % Display an error message
        %
        % @param message Message to display
        %
        function displayError(~, message)
            errordlg(message);
        end

        
        %
        % Update list of available tasks.
        %
        % @param taskList  Array of struct of available tasks.
        %
        function updateTaskList(obj, taskList)            
            % Remove old entries
            children = get(obj.taskMenu, 'Children');            
            for i = 1:length(children)
                delete(children(i));
            end
            
            % Add new entries
            for t = 1:length(taskList)
                uimenu(obj.taskMenu, 'Label', taskList(t).name, 'Callback', @(src, x) obj.onSetTask(taskList(t).name));
            end
        end
        
        
        %
        % Update list of datasets
        %
        % @param labels Cell array containing dataset names
        %
        function updateDatasetList(obj, labels)
            obj.datasetList.clear();
            
            for i = 1:length(labels)
                obj.datasetList.addItem(labels{i});
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
        % Update current overlap state.
        %
        % @param state Zero for disallowed, one for allowed
        %        
        function updateOverlapState(obj, state)
            obj.overlapState = state;
            
            if obj.overlapState == 0
                set(obj.overlapMenuItem, 'Label', 'Allow &overlap');
            else
                set(obj.overlapMenuItem, 'Label', 'Disallow &overlap');
            end
        end        
    end

    properties(Access = private)
        % Main GUI components
        mainWindow;
        stimulusList;
        datasetList;
        
        taskMenu;
        overlapMenuItem;
        
        overlapState;
        currentProjectPath = '';
    end    
    
    methods(Access = private)
        
        %
        % Setup graphical interface.
        %
        function setupGUI(obj)
            obj.mainWindow = GUIWindow();

            horizontalSplit = GUIBoxArray();
            horizontalSplit.setHorizontalDistribution([NaN NaN]);

            % Stimulus list
            obj.stimulusList = GUIList();

            verticalSplit = GUIBoxArray();
            verticalSplit.setVerticalDistribution([20 NaN 40]);
            verticalSplit.addComponent(GUILabel('Stimuli:'));
            verticalSplit.addComponent(obj.stimulusList);

            buttonAddStimulus = GUIButton('Add stimulus...');
            buttonAddStimulus.addEventListener('click', @(src) obj.onAddStimulus(src));
            buttonEditRegions = GUIButton('Edit regions...');
            buttonEditRegions.addEventListener('click', @(src) obj.onOpenStimulus(src));            

            buttons = GUIBoxArray();
            buttons.setMargin([0 0 0 0]);
            buttons.setHorizontalDistribution([NaN NaN]);
            buttons.addComponent(buttonAddStimulus);
            buttons.addComponent(buttonEditRegions);
            
            verticalSplit.addComponent(buttons);
            horizontalSplit.addComponent(verticalSplit);

            % Dataset list
            obj.datasetList = GUIList();

            verticalSplit = GUIBoxArray();
            verticalSplit.setVerticalDistribution([20 NaN 40]);
            verticalSplit.addComponent(GUILabel('Datasets:'));
            verticalSplit.addComponent(obj.datasetList);
            
            buttonAddDataset = GUIButton('Add dataset...');
            buttonAddDataset.addEventListener('click', @(src) obj.onAddDataset(src));
            buttonViewDataset = GUIButton('View dataset...');
            buttonViewDataset.addEventListener('click', @(src) obj.onOpenDataset(src));            
            
            buttons = GUIBoxArray();
            buttons.setMargin([0 0 0 0]);
            buttons.setHorizontalDistribution([NaN NaN]);
            buttons.addComponent(buttonAddDataset);
            buttons.addComponent(buttonViewDataset);
            
            verticalSplit.addComponent(buttons);
            horizontalSplit.addComponent(verticalSplit);
            
            obj.mainWindow.addComponent(horizontalSplit);
            
            % Create menus
            h = uimenu('Label', '&Project');
            uimenu(h, 'Label', '&New project...', 'Callback', @(src, x) obj.onNewProject(src));
            uimenu(h, 'Label', '&Open project...', 'Callback', @(src, x) obj.onOpenProject(src));
            uimenu(h, 'Label', '&Close project...', 'Callback', @(src, x) obj.onCloseProject(src));

            h = uimenu('Label', '&Options');
            obj.taskMenu = uimenu(h, 'Label','Set &task');            
            obj.overlapMenuItem = uimenu(h, 'Label', 'Disallow &overlap', 'Callback', @(src, x) obj.onToggleOverlap(src));
                        
            h = uimenu('Label', '&Analysis');
            uimenu(h, 'Label', 'Perform analysis...', 'Callback', @(src, x) obj.onPerformAnalysis(src));
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
        
        
        %
        % Function called when a task is selected
        %
        function onSetTask(obj, taskName)
            obj.invokeEventListeners('setTask', taskName);
        end
        

        %
        % Toggle whether overlap is allowed or not.
        %
        function onToggleOverlap(obj, ~)
            obj.invokeEventListeners('toggleOverlap');
        end

        
        %
        % Peform analysis button clicked.
        %
        function onPerformAnalysis(obj, ~)
            filename = uiputfile('*.csv', 'Choose output location');            
            if(isempty(filename)), return; end;            
            
            obj.invokeEventListeners('performAnalysis', filename);
        end

        
        %
        % Function called when adding a stimulus to the project
        %
        function onAddStimulus(obj, ~)
            if(obj.currentProjectPath ~= 0)
                
                fileTypes = {'*.wmv', 'Video files'; '*.jpg', 'Image files'};
                
                [filenames, pathname] = uigetfile( ...
                    fileTypes, 'Add stimulus', ...
                    'MultiSelect', 'On');
                
                % No file selected, return
                if(~iscell(filenames))
                    if(filenames == 0)
                        return
                    end
                end;
                
                % If one file was selected, create a cell
                if(~iscell(filenames))
                    filenames = {filenames};
                end
                
                h = waitbar(0, 'Adding stimuli');
                
                for i = 1:length(filenames)
                    waitbar(i/length(filenames), h);
                    try
                        filename = fullfile(pathname, filenames{i});
                        obj.invokeEventListeners('addStimulus', filename);
                    catch e
                        obj.displayError(['Could not import stimulus.' ...
                            10 10 'Error: ' e.message]);
                    end;
                end
                
                close(h);
            else
                warndlg('No active project, unable to add stimulus.');
            end
        end


        %
        % Function called a stimulus is to be opened
        %
        function onOpenStimulus(obj, src)            
            index = src.getSelectedIndex();
            obj.invokeEventListeners('openStimulus', index);
            obj.unsavedFlag = 0;
        end


        %
        % Function called when adding a dataset to the project
        %        
        function onAddDataset(obj, ~)
            if(obj.currentProjectPath ~= 0)                
                [filenames, pathname] = uigetfile( ...
                    {'*.txt', 'Datasets'}, 'Add dataset', ...
                    'MultiSelect', 'On');
                
                % No file selected, return
                if(~iscell(filenames))
                    if(filenames == 0)
                        return
                    end
                end;
                
                % If one file was selected, create a cell
                if(~iscell(filenames))
                    filenames = {filenames};
                end

                % Loop over all selected files and insert them
                for i = 1:length(filenames)
                    filename = fullfile(pathname, filenames{i});
                    obj.invokeEventListeners('addDataset', filename);
                end
            else
                warndlg('No active project, unable to add dataset');
            end            
        end

        
        %
        % Function called when a dataset has been selected
        %
        function onOpenDataset(obj, src)
            index = src.getSelectedIndex();
            obj.invokeEventListeners('openDataset', index);
        end
    end
end