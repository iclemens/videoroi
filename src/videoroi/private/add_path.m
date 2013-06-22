function add_path(dirName)
% ADD_PATH adds a directory to the path

    p = textscan(path, '%s', 'Delimiter', ';'); 
    p = p{1};
    
    if ~any(ismember(p, dirName))
        addpath(dirName);
    end
