classdef VideoROITaskFactory < handle
%
% Constructs classes implementing task-dependent logic.
%

    methods(Static)


        function taskInstance = obtainTaskInstance(taskName)
            % Returns an instance of the task-class
            
            % First determine directory containing task-logic classes
            sourceDir = fileparts(mfilename('fullpath'));
            taskDir = fullfile(sourceDir, 'TaskLogic');            

            add_path(taskDir);
                       
            % Create instance of task
            if ~isempty(taskName)
                taskInstance = feval(taskName);
            else
                error('VideoROITaskFactory:InvalidTask', 'Invalid task specified');
            end
        end
        
        
        function taskList = enumerateTasks()
            % Returns a list of all supported tasks
            
            % First determine directory containing task-logic classes
            sourceDir = fileparts(mfilename('fullpath'));
            taskDir = fullfile(sourceDir, 'TaskLogic');
            
            % Add it to the path and enumerate files
            add_path(taskDir);            
            taskFiles = dir(taskDir);
            
            % Create list of all non-directories with extension .m
            taskList = struct('name', {});
                       
            for i = 1:length(taskFiles)
                if taskFiles(i).isdir, continue; end;
                
                [~, file, ext] = fileparts(taskFiles(i).name);
                
                if strcmp(ext, '.m')
                    j = length(taskList) + 1;
                    taskList(j).name = file;
                end
            end
        end        
    end
    
    
end