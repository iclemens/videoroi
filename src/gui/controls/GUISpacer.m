classdef GUISpacer < GUIComponent
    
    properties
        margin;
    end
    
    methods
        function obj = GUISpacer()
            obj = obj@GUIComponent();            
            obj.margin = [5 5 5 5];
        end
        
        function setMargin(obj, margin)
            obj.margin(1:4) = margin;
        end
        
       function [minimum, maximum] = getSizeConstraints(obj)
            minimum = [0 0];
            maximum = [Inf Inf];
       end
        
        function doResize(obj, bounds)            
            obj.doResize@GUIComponent(bounds);
        end
    end                
end