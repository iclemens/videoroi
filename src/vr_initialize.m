function vr_initialize
% VR_INITIALIZE  Adds the VideoROI Toolbox to the path. This function
% should be called at the start of all other VideoROI functions.

    % Setup global defaults structure.
    global vr_defaults;
    persistent vr_initialized;
    
    if ~vr_initialized
        vr_initialized = 1;
        vr_defaults = struct();
    end;

    % Make sure that all toolbox-directories are on the path.
    pth = fileparts(mfilename('fullpath'));
    
    add_to_path(pth);
    add_to_path(fullfile(pth, 'utilities'));
    add_to_path(fullfile(pth, 'algorithms'));
    add_to_path(fullfile(pth, 'idf'));
    add_to_path(fullfile(pth, 'gui'));
    add_to_path(fullfile(pth, 'gui/controls'));
    add_to_path(fullfile(pth, 'videoroi'));
    add_to_path(fullfile(pth, 'mmread'));


    function add_to_path(dirname)
    % ADD_TO_PATH  Adds a directory to the matlab path. If the directory
    % was already on the path, this function does nothing.
        
        % Split path string
        pth_items = textscan(path, '%s', 'delimiter', pathsep);

        % Add directory to path if required.
        if ~any(strcmp(pth_items{1}, dirname))
            addpath(dirname);
        end
    end       
end