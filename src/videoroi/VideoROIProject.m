classdef VideoROIProject < EventProvider
%
% Manages VideoROI project directories.
%
% Overview of a project directory:
%  manifest.dat
%   version - version of the datafile
%   stimuli - struct array with names and dimensions
%   datasets - struct array with names
% 
%  stimuli/VIDEO/video.wmv or .jpg
%  stimuli/VIDEO/regions/DATE.roi
%
%  datasets/DATASET/dataset.txt
%

    properties(Access = private)
        projectDirectory = '';
        
        taskName = '';
        
        version = 0;
        stimuli = struct('name', {}, 'frames', {}, 'width', {}, 'height', {}, 'filename', {});
        datasets = struct('name', {}, 'filename', {});
    end;

    
    methods(Access = public)
        function obj = VideoROIProject(projectDirectory)
            % Creates or opens a VideoROI project
            
            manifestFile = fullfile(projectDirectory, 'manifest.dat');
            
            if(~exist(manifestFile, 'file'))
                if(~obj.isEmptyDirectory(projectDirectory))
                    error('VideoROI:DirectoryNotSuitable', ...
                        ['Directory %s is not empty ' ...
                         'and therefore not suitable to host a project.'], projectDirectory);
                end
                
                obj.version = 2;
                obj.saveManifest(manifestFile);
                                
                mkdir(projectDirectory, 'stimuli');
                mkdir(projectDirectory, 'datasets');
            end

            obj.loadManifest(manifestFile);
            obj.projectDirectory = projectDirectory;
        end                           
                             
                
        function setTaskName(obj, taskName)
            % Changes the task associated with the given experiment

            obj.taskName = taskName;
        end
        
        
        function taskName = getTaskName(obj)
            % Returns task associated with this project
            
            taskName = obj.taskName;
        end
                       
        
        function addStimulus(obj, filename, localName)
            % Adds a stimulus (either a video or an image) to the project
        
            [~, name, ext] = fileparts(filename);
            
            if(nargin < 3)
                localName = lower(name);
            end

            if(isempty(filename) || isempty(localName))
                error('VideoROI:InvalidName', ...
                    'The specified filename is invalid');
            end
            
            if(any(strcmpi([name ext], {obj.stimuli(:).filename})))
                error('VideoROI:VideoAlreadyExists', ...
                    'A stimulus with that name already exists');
            end

            % Add file to manifest
            obj.stimuli(end + 1).name = localName;
            obj.stimuli(end).filename = lower([name ext]);

            % Create directories if they do not exists
            videoDir = create_directories(obj.projectDirectory, 'stimuli', obj.stimuli(end).name);
            create_directories(videoDir, 'regions');

            % Copy original file into project
            videoFile = fullfile(videoDir, obj.stimuli(end).filename);            
            copyfile(filename, videoFile);            

            % Update stimulus metadata
            obj.updateStimulusMetadata(length(obj.stimuli));            
            
            % Make sure video list is sorted by name
            obj.stimuli = sortstruct(obj.stimuli, 'name');
            
            % Save manifest
            obj.saveManifest();            
        end
              
        
        function addDataset(obj, filename, localName)
            % Adds an eye-tracking dataset to the project.
            
            [~, name, ext] = fileparts(filename);

            if(nargin < 3)
                localName = lower(name);
            end

            if(isempty(filename) || isempty(localName))
                error('VideoROI:InvalidName', ...
                    'The specified filename is invalid');
            end            
            
            if(any(strcmpi([name ext], {obj.stimuli(:).filename})))
                error('VideoROI:DatasetAlreadyExists', ...
                    'A dataset with that name already exists');
            end

            % Add file to manifest
            obj.datasets(end + 1).name = localName;
            obj.datasets(end).filename = lower([name ext]);
            
            % Create directories if they do not exists
            datasetDir = create_directories(obj.projectDirectory, 'datasets', obj.datasets(end).name);

            % Copy original file into project
            datasetFile = fullfile(datasetDir, obj.datasets(end).filename);            
            copyfile(filename, datasetFile);            

            % Make sure datasets are sorted by name
            obj.datasets = sortstruct(obj.datasets, 'name');            
            
            % Save manifest
            obj.saveManifest();            
        end                
        
        
        function filename = getNextROIFilename(obj, stimulus)
            % Returns filename to save ROI information into
            %  videos/VIDEO/regions/DATE.roi
            %
            % The stimulus can be referenced by both name and information
            % struct, the latter is preferred.            
            
            if(isstruct(stimulus))
                stimulus = stimulus.name;
            end
            
            regionDirectory = fullfile(obj.projectDirectory, 'stimuli', stimulus, 'regions');
            
            if(~exist(regionDirectory, 'dir'))
                error('The specified video does not exist within the project');
            end                
            
            regionName = datestr(now, 'yyyymmdd-HHMMSS.roi');
            filename = fullfile(regionDirectory, regionName);
        end

        
        function filename = getLatestROIFilename(obj, stimulus)
            % Returns the latest ROI file for a given video.
            %
            % The stimulus can be referenced by both name and information
            % struct, the latter is preferred.
            
            % Extract name in case an information struct was passed.
            if(isstruct(stimulus))
                stimulus = stimulus.name;
            end
            
            regionDirectory = fullfile(obj.projectDirectory, 'stimuli', stimulus, 'regions');
            
            if(~exist(regionDirectory, 'dir'))
                error('The specified video does not exist within the project');
            end                

            listing = dir(regionDirectory);            
            listing = sort({listing(:).name});
            
            if(length(listing) > 2)            
                filename = fullfile(regionDirectory, listing{end});
            else
                filename = '';
            end
        end
        
        
        function count = getNumberOfDatasets(obj)
            % Number of (eye-tracking) datasets
            
            count = length(obj.datasets);
        end
        
        
        function count = getNumberOfStimuli(obj)
            % Number of stimuli (images and videos)
            
            count = length(obj.stimuli);
        end               
        
        
        function info = getInfoForStimulus(obj, index)
            % Returns metadata and resourcepath for a stimulus.
            
            % Name of stimulus given, convert to index
            if ischar(index)
                index = obj.findStimulusByName(index);            

                if(isempty(index))
                    info = NaN;
                    return;
                end;
            end;
            
            info = obj.stimuli(index);           
            
            if(isempty(info))
                info = NaN;
                return;
            end
            
            stimulusPath = fullfile(obj.projectDirectory, 'stimuli', info.name);            
            info.resourcepath = stimulusPath;            
        end
        
        
        function info = getInfoForDataset(obj, index)
            % Returns metadata and resourcepath for a dataset
            info = obj.datasets(index);            
            
            if(isempty(info))
                info = NaN;
                return;
            end
            
            datasetDir = fullfile(obj.projectDirectory, 'datasets', info.name);
            info.resourcepath = datasetDir;                        
        end
    end
    
    methods(Access = private)
        % Checks whether the given directory is empty
        function empty = isEmptyDirectory(~, directory)
            listing = dir(directory);
            listing(strcmp({listing.name}, '.')) = [];
            listing(strcmp({listing.name}, '..')) = [];
            
            empty = isempty(listing);
        end

        
        function index = findStimulusByName(obj, stimulusName)
            % Finds a stimulus given its name.
            index = strcmpi({obj.stimuli(:).name}, stimulusName);
            
            if(sum(index) > 1)
                error('More than one stimulus found with this name');
            end;
        end
        
        
        % Loads state from the manifest file
        function loadManifest(obj, manifestFile)
            if(nargin < 2)
                manifestFile = fullfile(obj.projectDirectory, 'manifest.dat');
            end            
            
            manifest = load(manifestFile, '-mat');

            % Old version detected, convert to newer structure...
            if(manifest.version == 1)
                h = waitbar(0, 'Upgrading project directory...');
                
                movefile('videos', 'stimuli');
                
                obj.version = 2;
                obj.datasets = sortstruct(manifest.datasets, 'name');
                obj.stimuli = sortstruct(manifest.videos, 'name');
                
                % Attempt to add meta-data to stimulus structure
                obj.updateAllMetadata();
                
                obj.saveManifest(manifestFile);                
                close(h);
                
                % Attempt to read the file we have just saved
                obj.loadManifest(manifestFile);
                
                return;
            end;

            % Read latest version
            if(manifest.version == 2)
                manifest.stimuli = sortstruct(manifest.stimuli, 'name');
                manifest.datasets = sortstruct(manifest.datasets, 'name');           
            
                obj.version = manifest.version;
                obj.datasets = manifest.datasets;            
                obj.stimuli = manifest.stimuli;
                
                if isfield(manifest, 'taskName')
                    obj.taskName = manifest.taskName;
                end
                
                return;
            end;
            
            % None of the above handled the file, thus it is not supported
            error('VideoROI:VersionNotSupported', ...
                ['The project version is not supported by this ' ...
                 'version of VideoROI.']);            
        end


        function saveManifest(obj, manifestFile)
            % Saves state to the manifest file
            
            if(nargin < 2)
                manifestFile = fullfile(obj.projectDirectory, 'manifest.dat');
            end

            version = obj.version;
            stimuli = obj.stimuli;
            datasets = obj.datasets;
            taskName = obj.taskName;
            
            save(manifestFile, 'version', 'stimuli', 'datasets', 'taskName');
        end

        
        function updateAllMetadata(obj)
            % Updates metadata for all stimuli
            % This is required when the project is upgraded to a new version
            
            for s = 1:obj.getNumberOfStimuli()
                obj.updateStimulusMetadata(s);
            end            
        end
        

        function updateStimulusMetadata(obj, index)
            % Update metadata associated with stimulus
        
            videoInfo = obj.getInfoForStimulus(index);
            
            if ~isstruct(videoInfo) && isnan(videoInfo)
                error('VideoROI:InvalidStimulus', ...
                    'Stimulus identifier is invalid.');
            end                       
            
            stimulus = VideoROIStimulus();
            stimulus.openStimulus(fullfile(videoInfo.resourcepath, videoInfo.filename));
            
            obj.stimuli(index).frames = stimulus.getNumberOfFrames();
            obj.stimuli(index).width = stimulus.getFrameWidth();
            obj.stimuli(index).height = stimulus.getFrameHeight();           
        end
        
    end
       
end