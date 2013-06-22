function indices = idf_find_columns(columns, header)
% IDF_FIND_COLUMNS - Determines column indices

    % In case only one column is given, convert
    % to a cell array
    if(~iscell(columns))
        columns = {columns};
    end
    
    indices = nan(1, length(columns));
    
    % Determine indices for each column
    for i = 1:length(columns)
        idx = find(strcmp(columns{i}, header.Columns));
        
        if(~isempty(idx))
            indices(i) = idx;
        end
    end
end