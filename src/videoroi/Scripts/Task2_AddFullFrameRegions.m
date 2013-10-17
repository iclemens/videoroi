classdef Task2_AddFullFrameRegions
  
  methods(Access = public)

    % Returns meta-data about this script
    function scriptInfo = getScriptInfo(~)
      scriptInfo.caption = 'Task2: Add full frame regions';
    end


    % Runs the script
    function executeScript(obj, project)      
      n = project.getNumberOfStimuli();
      
      for s = 1:n
        stimInfo = project.getInfoForStimulus(s);
        regions = VideoROIRegions(stimInfo);
        
        tokens = regexp(stimInfo.name, '[a-z]+[0-9]+_([0-9])+_([a-z]+)_([a-z]+)_([a-z]+)_([a-z]+)', 'tokens');
        tokens = tokens{1};
        
        if numel(tokens) < 4
          stimInfo.name
          tokens{:}
        else
          
        end

        regions.addRegion(obj.capitalize(tokens{4}), 1);
        regions.setRegionPosition(1, 1, [1 1 stimInfo.width stimInfo.height]);
        
        regionsFilename = project.getNextROIFilename(stimInfo);
        regions.saveRegionsToFile(regionsFilename);        
      end
    end
  end
  
  
  methods(Access = private)
    function str = capitalize(~, str)
      str = [upper(str(1)) lower(str(2:end))];
    end
  end
end