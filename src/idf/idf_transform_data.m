function [data, header] = idf_transform_data(cfg, data, header)
% [data, header] = IDF_TRANSFORM_DATA(data, header) 
% Invokes a callback function on each sample

    % Determine number of columns
    n_columns = length(header.Columns);

    col_src = idf_find_columns(cfg.src, header);
    col_dest = idf_find_columns(cfg.dest, header);

    if(any(isnan(col_src)))
        error('One of the source columns could not be found!');
    end

    % Allocate destination columns if they do not already exist
    nex = find(isnan(col_dest));
    for i = nex
        n_columns = n_columns + 1;
        col_dest(i) = n_columns;
        
        if(iscell(cfg.dest))
            header.Columns{col_dest(i)} = cfg.dest{i};
        else
            header.Columns{col_dest(i)} = cfg.dest;
        end
    end
    
    % Process all data using the callback
    for i = 1:length(data)
        % If there are no samples, at least extend matrix
        % such that it has enough columns.
        if isempty(data(i).samples)
            sz = max(size(data(1).samples, 2), max(col_dest));
            data(i).samples = zeros(0, sz);
            continue;
        end;
        
        source = data(i).samples(:, col_src);        
        dest = cfg.procfcn(cfg, source);        
        data(i).samples(:, col_dest) = dest;        
    end  
end