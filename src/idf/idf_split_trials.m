function data = idf_split_trials(s, m)
% Separate per-trial data
% s - Samples
% m - Messages

data = struct('samples', {}, 'messages', {});
trials = unique([m.trial]);

for t = trials
    data(t).samples = s( s(:, 2) == t, :);
    data(t).messages = m([m.trial] == t);
end