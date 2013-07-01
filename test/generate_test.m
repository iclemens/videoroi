
stimulusDirectory = 'E:/Dropbox/Work/2012 VideoROI/Stimuli/Task 4/';
stimuli = {...
    '14 cashmere mafia - s01e06 - NEG gesprek vrouw baas.wmv', ...
    '25 hustle s07e05 - 54.50 - POS gesprek met mark.wmv'};

cfg = struct();

cfg.stimuli = strcat(stimulusDirectory, stimuli);

cfg.datasetFilename = 'fakedata.txt';
cfg.analysisFilename = 'fakeanalysis.csv';

DatasetGenerator(cfg);
