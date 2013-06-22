function [data, header] = idf_pixels_to_angles(data, header, screen)
    cfg = [];
    cfg.src = {'R POR X [px]', 'R POR Y [px]'};
    cfg.dest = {'R Gaze X [rad]', 'R Gaze Y [rad]'};

    cfg.procfcn = @(cfg, src) [ ...
            atan2(screen.distance, (src(:, 1) ./ screen.resolution(1) - 0.5) .* screen.dimensions(1)) - 0.5 * pi, ...
            atan2(screen.distance, (src(:, 2) ./ screen.resolution(2) - 0.5) .* screen.dimensions(2)) - 0.5 * pi];

    idf_transform_pixels(cfg, data, header);
end