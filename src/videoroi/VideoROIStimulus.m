classdef VideoROIStimulus < handle
  %
  % Represents a visual stimulus, which can be either a still image or
  % a video. This class presents still images as 1-frame videos.
  %
  
  properties(Access = private)
    type = 'none';
    
    videoReader;
    imageBuffer;
    
    numFrames = 0;
    
    frameWidth = 0;
    frameHeight = 0;
  end;
  
  
  methods(Access = private)
    % Opens a video (motion image) stimulus
    function openVideo(obj, videoFile)
      try
        obj.videoReader = VideoReaderMM(videoFile);
        obj.type = 'video';
      catch e
        message = [e.message 10 10 'Filename = ' videoFile];
        error(message);
      end
      
      obj.numFrames = obj.videoReader.NumberOfFrames;
      
      if(isempty(obj.numFrames))
        fprintf('Stimulus: Scanning file to determine amount of frames...\n');
        obj.videoReader.read(inf);
        obj.numFrames = obj.videoReader.NumberOfFrames;
      end
      
      fprintf('Stimulus: Opened video with %d frames.\n', obj.numFrames);
      
      I = obj.readFrame(1);
      obj.frameWidth = size(I, 2);
      obj.frameHeight = size(I, 1);
    end
    
    
    % Opens an still-image stimulus
    function openImage(obj, imageFile)
      try
        obj.imageBuffer = imread(imageFile);
        obj.type = 'image';
      catch e
        error('The image file specified could not be found.');
      end
      
      obj.numFrames = 1;
      
      size(obj.imageBuffer);
      
      obj.frameWidth = size(obj.imageBuffer, 2);
      obj.frameHeight = size(obj.imageBuffer, 1);
    end
  end
  
  
  methods
    function obj = VideoROIStimulus()
      obj.type = 'none';
      obj.numFrames = 0;
      obj.frameWidth = 0;
      obj.frameHeight = 0;
    end
    
    
    % Opens a stimulus, determining file-type by extension
    function openStimulus(obj, stimulusFile)
      videoExt = {'.wmv', '.avi', '.mpg', '.mpeg'};
      imageExt = {'.jpeg', '.jpg', '.png', '.bmp', '.gif'};
      
      [path, name, ext] = fileparts(stimulusFile);
      
      ext = lower(ext);
      
      if any(strcmp(ext, videoExt))
        obj.openVideo(stimulusFile);
      elseif any(strcmp(ext, imageExt))
        obj.openImage(stimulusFile);
      else
        error('VideoROIStimulus:FormatNotRecognized', ...
          'Invalid stimulus format: (%s)', ext);
      end
    end
    
    
    % Query number of frames
    function numFrames = getNumberOfFrames(obj)
      numFrames = obj.numFrames;
    end;
    
    
    % Query frame rate
    function frameRate = getFrameRate(obj)
      if(strcmp(obj.type, 'video') && isobject(obj.videoReader))
        frameRate = obj.videoReader.FrameRate;
      else
        frameRate = 30;
      end
    end
    
    % Query frame width
    function frameWidth = getFrameWidth(obj)
      frameWidth = obj.frameWidth;
    end
    
    
    % Query frame height
    function frameHeight = getFrameHeight(obj)
      frameHeight = obj.frameHeight;
    end
    
    
    % Retrieves a single frame
    function I = readFrame(obj, index)
      if strcmp(obj.type, 'video')
        try
          I = obj.videoReader.read(index);
        catch
          I = obj.videoReader.read(index);
        end;
      elseif strcmp(obj.type, 'image')
        I = obj.imageBuffer;
      else
        fprintf('Stimulus: Type %s not recognized.\n', obj.type);
        I = zeros(1, 1, 3);
      end
    end
  end;
  
end