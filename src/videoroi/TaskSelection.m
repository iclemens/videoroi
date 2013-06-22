classdef TaskSelection < handle
    
    properties(Access = private)
        window;
        taskList;
    end
    
    methods(Access = public)
        function obj = TaskSelection()
            % Create task-selection window
            
            obj.window = GUIWindow();
            obj.taskList = GUIList();
            
            distr = GUIBoxArray();
            distr.setVerticalDistribution([NaN 30]);

            button = GUIButton('Choose task');

            distr.addComponent(obj.taskList);
            distr.addComponent(button);

            obj.window.addComponent(distr);            
            obj.window.setTitle('Tasks');

            obj.populateTaskList();
        end
    end
    
    methods(Access = private)
        
        function populateTaskList(obj)
            % Add valid task-names to the list
            
            obj.taskList.clear();
            
            tasks = VideoROITaskFactory.enumerateTasks();
            for t = 1:length(tasks)
                obj.taskList.addItem(tasks(t).name);
            end
            
        end;
        
    end
    
end