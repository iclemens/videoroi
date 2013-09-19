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
    end

    properties(Access = private)
        % Main GUI components
        mainWindow;
        stimulusList;
        datasetList;
        
        taskMenu;
        overlapMenuItem;
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
            
            buttons = GUIBoxArray();
            buttons.setMargin([0 0 0 0]);
            buttons.setHorizontalDistribution([NaN NaN]);
            buttons.addComponent(GUIButton('Add stimulus...'));
            buttons.addComponent(GUIButton('Edit regions...'));
            
            verticalSplit.addComponent(buttons);
            horizontalSplit.addComponent(verticalSplit);

            % Dataset list
            obj.datasetList = GUIList();

            verticalSplit = GUIBoxArray();
            verticalSplit.setVerticalDistribution([20 NaN 40]);
            verticalSplit.addComponent(GUILabel('Datasets:'));
            verticalSplit.addComponent(obj.datasetList);
            
            buttons = GUIBoxArray();
            buttons.setMargin([0 0 0 0]);
            buttons.setHorizontalDistribution([NaN NaN]);
            buttons.addComponent(GUIButton('Add dataset...'));
            buttons.addComponent(GUIButton('View dataset...'));
            
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
        
        
        function onNewProject(obj, src)
        end
        
        function onOpenProject(obj, src)
        end
        
        function onCloseProject(obj, src)
        end

        function onToggleOverlap(obj, src)
        end
        
        function onPerformAnalysis(obj, src)
        end
    end
end