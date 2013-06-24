function clusters = idf_cluster_mask(mask)
% IDF_CLUSTER_MASK  Returns a matrix containing start (column 1) and
% stop (column 2) sample numbers for each cluster of 1s found in the
% the mask.    

    % Empty mask means no clusters
    if(isempty(mask))
        clusters = zeros(0, 2);
        return;
    end

    mask = mask(:);

    seq_start = find((mask(1:end-1) == 0) & (mask(2:end) == 1)) + 1;
    seq_stop = find((mask(1:end-1) == 1) & (mask(2:end) == 0));
    
    if(mask(1) == 1)
        seq_start = [1; seq_start];
    end
    
    if(mask(end) == 1)
        seq_stop = [seq_stop; length(mask)];
    end

    clusters = [seq_start seq_stop];
end