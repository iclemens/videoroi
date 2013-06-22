classdef GUIAxes < GUIComponent
    
    properties
        handle;
        margin;
        
        onConstruction;
    end
    
    methods
        function obj = GUIAxes()
            obj = obj@GUIComponent();            
            obj.margin = [5 5 5 5];
            obj.handle = 0;            
        end

        function doConstruction(obj)
            obj.invokeEventListeners('construction');
        end
                
        function constructObject(obj)
            parentHandle = obj.getParentHandle();
            
            if(parentHandle ~= 0)            
                obj.handle = axes('Parent', parentHandle, 'Units', 'pixels');
                box(obj.handle, 'on');                
                
                obj.doConstruction();
            end
        end        

        function [h] = getHandle(obj)
            h = obj.handle;
        end        
        
         function setParent(obj, parent)
            obj.setParent@GUIComponent(parent);
            
            parentHandle = obj.getParentHandle();
            
            if(parentHandle ~= 0)
                if(~obj.handle), obj.constructObject(); end;
                set(obj.handle, 'Parent', parentHandle);
            end
        end        
        
        function setMargin(obj, margin)
            obj.margin(1:4) = margin;
        end
               
        function doResize(obj, bounds)
            bounds(1:2) = bounds(1:2) + obj.margin(1:2);
            bounds(3:4) = bounds(3:4) - obj.margin(3:4) - obj.margin(1:2);

            set(obj.handle, 'OuterPosition', bounds);
            
            obj.doResize@GUIComponent(bounds);
        end
    end                
end