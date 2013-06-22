classdef VideoReaderMM < hgsetget
    
    properties(Access='private')
        FileName
        
        FrameBuffer
    end
    
    properties(GetAccess='public', SetAccess='private')
        Name

        FrameRate
        Height
        NumberOfFrames
        Width
    end
    
    methods(Access='public')
        
        function obj = VideoReaderMM(fileName, varargin)
            if(~exist('mmread', 'file'))
                dirname = fileparts(mfilename('fullpath'));                
                addpath(fullfile(dirname, '..', 'mmread'));
            end
            
            % If no file name provided.
            if nargin == 0
                error(message('MATLAB:audiovideo:VideoReader:noFile'));
            end

            if ~exist(fileName, 'file')
                error('Specified file does not exist.');
            end
            
            % Initialize the object.
            obj.init(fileName);

            % Set properties that user passed in.
            if nargin > 1
                set(obj, varargin{:});
            end
        end
        
        function img = read(obj, index)
            %video = mmread(obj.FileName, index, [], false, true);
            %img = video.frames(1).cdata;            
            %img = squeeze(obj.FrameBuffer(index, :, :, :));
            img = obj.FrameBuffer.frames(index).cdata;
        end
    end
    
    
    methods(Access='private')
        function init(obj, filename)
            obj.FileName = filename;
            
            [p, n, e] = fileparts(filename);
            obj.Name = [n e];

            % Capture all frames
            obj.FrameBuffer = mmread(obj.FileName, [], [], false, true);                        
            
            % If the number could not be determined, produce an error
            if(obj.FrameBuffer.nrFramesTotal < 0)
                error('Could not determine number of frames... bailing');
            end
            
            obj.FrameRate = obj.FrameBuffer.rate;
            obj.NumberOfFrames = obj.FrameBuffer.nrFramesTotal;
            
            obj.Width = obj.FrameBuffer.width;
            obj.Height = obj.FrameBuffer.height;                        
        end
    end
    
end