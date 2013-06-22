function clusters = idf_cluster_mask(mask)
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