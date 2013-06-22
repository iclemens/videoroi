function data = idf_parse_frame_msgs(data)
% Parses frame messages and adds
%  data(:).movie and data(:).frames elements

h = waitbar(0, 'Processing frame messages');

for t = 1:length(data)
    data(t).movie = -1;
    data(t).frames = nan(size(data(t).samples, 1), 1);
    
    current_frame = NaN;
    current_time = 0;
    
    for m = 1:length(data(t).messages)
        msg = data(t).messages(m);

        % Mark all frames BEFORE this message as beloning 
        % to the current frame
        frame_indices = ...
            (data(t).samples(:, 1) >= current_time) & ...
            (data(t).samples(:, 1) < msg.time);
        
        data(t).frames(frame_indices) = current_frame;        
        
        % Check whether the current frame has changed
        if strncmpi(msg.message, '# Message: ITI', 14)           
            current_time = msg.time;
            current_frame = NaN;
        end
        
        if strncmpi(msg.message, '# Message: Frame: ', 17)
            frame = str2double(msg.message(18:end));
            current_time = msg.time;            
            current_frame = frame;
        end
        
        if strncmpi(msg.message, '# Message: FrameNr: ', 19)
            frame = str2double(msg.message(20:end));
            current_time = msg.time;            
            current_frame = frame;
        end          
        
        % Parse movie string
        if strncmpi(msg.message, '# Message: Movie: ', 18)
            data(t).movie = strtrim(msg.message(19:end));
        end                            
    end
    
    if(data(t).movie == -1)
        %disp(['No movie for trial ' num2str(t)]);
        waitbar(t/length(data), h, 'Processing frame messages');
    else
        %disp(['Trial ' num2str(t) ' is related to movie ' data(t).movie]);
        waitbar(t/length(data), h, ['Movie: ' data(t).movie]);
    end;    
end

close(h);