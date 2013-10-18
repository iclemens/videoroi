classdef Task3_AddFullFrameRegions
  
  methods(Access = public)

    % Returns meta-data about this script
    function scriptInfo = getScriptInfo(~)
      scriptInfo.caption = 'Task3: Add full frame regions';
    end


    % Runs the script
    function executeScript(obj, project)      
      n = project.getNumberOfStimuli();
      
      for s = 1:n
        stimInfo = project.getInfoForStimulus(s);
        regions = VideoROIRegions(stimInfo);               

        regions.addRegion(stimInfo.name, 1);
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