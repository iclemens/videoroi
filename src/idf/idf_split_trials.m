function data = idf_split_trials(s, m)
% Separate per-trial data
% s - Samples
% m - Messages

data = struct('samples', {}, 'messages', {});
trials = unique([m.trial]);

for t_id = 1:length(trials)
    data(t_id).trialnr = trials(t_id);
    data(t_id).samples = s( s(:, 2) == trials(t_id), :);
    data(t_id).messages = m([m.trial] == trials(t_id));
end