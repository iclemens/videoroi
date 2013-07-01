function [samples, messages, header] = read_idf(filename)
% READ_IDF reads IDF eye-tracking data from a file
%
% Terminology:
%  DIA: Diameter
%  CR1: First corneal reflexion
%  POR: Point of regard (on-screen pixel value)
%
   
    fid = fopen(filename, 'r');

    if(fid == -1)
        error('Could not open file');
    end

   
    h = waitbar(0, 'Loading eye-traces...');    
    
    % %%%%%%%%%%%%%%%%%%%%%%%%
    % Read header into struct
    line = fgetl(fid);
    
    header = struct();
    blockName = '';  
    
    while(length(line) < 2 || strcmp(line(1:2), '##'))              
        line = strtrim(line(3:end));
        
        if isempty(line)
            line = fgetl(fid);            
            continue; 
        end;       
        
        if(line(1) == '[' && line(end) == ']')
            blockName = line(2:end-1);
            blockName = strrep(blockName, ' ', '_');
            header.(blockName) = struct();
        else
            pos = strfind(line, ':');
            key = strtrim(line(1:pos-1));
            key = strrep(key, ' ', '_');
            key(key == '[' | key == ']') = [];
            
            value = strtrim(line((pos+1):end));            
            header.(blockName).(key) = value;
        end
        
        line = fgetl(fid);
    end
   
    
    % %%%%%%%%%%%%%%%%%%%
    % Read sample-header
    
    Columns = {};
    remain = line;
    n_columns = 0;
    
    while true
        [str, remain] = strtok(remain, char(9));
        if isempty(str), break; end;
        
        n_columns = n_columns + 1;
        Columns{n_columns} = strtrim(str);        
    end;

    % We do not store type, remove column
    Columns(2) = [];
    
    header.Columns = Columns;
    
    
    % %%%%%%%%%%%%%%%%%%%%%%%%%%
    % Read samples and messages
    
    % Read samples
    messages = struct('time', {}, 'trial', {}, 'message', {});

    % TIME TYPE TRIAL
    sample_nr = 0;
    
    nSamples = str2double(header.Presentation.Number_of_Samples);
    samples = nan(nSamples, 10);    
    
    l = 0;
    
    while(~feof(fid))
        %if(mod(sample_nr, 1000) == 0), disp(sample_nr); end;
        l = l + 1;
        if(mod(l, 500) == 0)
            waitbar(sample_nr / nSamples, h);
        end
        
        % Read as many SMP lines as possible
        lineData = textscan(fid, '%u64 %c%c%c %d %f %f %f %f %f %f %f %f');
        nLines = length(lineData{13});

        samples(sample_nr + (1:nLines), 1) = lineData{1}(1:nLines);
        samples(sample_nr + (1:nLines), 2) = lineData{5}(1:nLines);
        samples(sample_nr + (1:nLines), 3:10) = [lineData{6:13}];
        
        sample_nr = sample_nr + nLines;
        
        % Try and finish reading MSG line        
        idx = length(messages) + 1;        
        messages(idx).time = lineData{1}(end);
        messages(idx).trial = lineData{5}(end);
        messages(idx).message = fgetl(fid);                            
    end;
    
    close(h);
       
    fclose(fid);
