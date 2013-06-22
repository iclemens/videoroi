classdef ROIPropertiesView < handle
    properties(Access = private)
        window;
        name;
    end
    
    methods
        function obj = ROIPropertiesView()
            obj.window = GUIWindow();
            obj.name = GUITextbox();
            
            obj.window.addComponent(obj.name);
            
            obj.window.setTitle('ROI Properties');
            obj.name.setText('ROIName');
        end
    end
end