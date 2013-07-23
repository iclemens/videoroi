% This script creates a new project containing all stimuli from one directory and
% all data files form another. Regions of interest are not yet imported.

%% Constants
projectdirectory = '/Users/ivar/Documents/CompleteProject';
datadirectory = '/Users/ivar/Dropbox/Work/2012 VideoROI/Data/Task 4';
stimulusdirectory = '/Users/ivar/Dropbox/Work/2012 VideoROI/Stimuli/Task 4';
regiondirectory = '/Users/ivar/Dropbox/Work/2012 VideoROI/Regions';

%% Create project
mkdir(projectdirectory);
project = VideoROIProject(projectdirectory);
project.setTaskName('Task4Logic');

%% Import datafiles
datafiles = dir(datadirectory);
for i_d = 1:length(datafiles)
    if datafiles(i_d).isdir, continue; end;
    datafile = fullfile(datadirectory, datafiles(i_d).name);    
    project.addDataset(datafile);
end

%% Import stimuli
stimulusfiles = dir(stimulusdirectory);
for i_s = 1:length(stimulusfiles)
    if stimulusfiles(i_s).isdir, continue; end;
    stimulusfile = fullfile(stimulusdirectory, stimulusfiles(i_s).name);
    project.addStimulus(stimulusfile);
end

%% Load regions of interest
regionfiles = dir(regiondirectory);
for i_r = 1:length(regionfiles)
    if regionfiles(i_r).isdir, continue; end;
    regionfile = fullfile(regiondirectory, regionfiles(i_r).name);
    tmp = load(regionfile, '-mat');
    [path, name, ext] = fileparts(tmp.videoName);   
    targetfile = project.getNextROIFilename(name);
    copyfile(regionfile, targetfile);
end

%% Analyze
cfg = [];
cfg.projectdirectory = projectdirectory;
VideoROIAnalysis(cfg);
