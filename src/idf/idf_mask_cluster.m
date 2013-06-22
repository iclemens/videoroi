function mask = idf_mask_cluster(clusters, len)
    mask = false(len, 1);
    for c = 1:size(clusters, 1)
        mask(clusters(c, 1):clusters(c, 2)) = true;
    end
end