classdef GUITextbox < GUIComponent
    
    properties
        handle;
        margin;
        text;
    end
    
    methods
        function obj = GUITextbox()
            obj = obj@GUIComponent();            
            obj.margin = [5 5 5 5];
            obj.handle = 0;
            obj.text = '';
        end

        function constructObject(obj)
            parentHandle = obj.getParentHandle();
            
            if(parentHandle ~= 0)            
                obj.handle = uicontrol('Parent', parentHandle, 'Style', 'edit', 'Units', 'pixels', 'String', obj.text);
                set(obj.handle, 'BackgroundColor', [1 1 1]);
            end
        end
        
        function setParent(obj, parent)
            obj.setParent@GUIComponent(parent);
            
            parentHandle = obj.getParentHandle();
            
            if(parentHandle ~= 0)
                if(~obj.handle), constructObject(obj); end;                
                set(obj.handle, 'Parent', parentHandle);
            end
        end
        
        function setMargin(obj, margin)
            obj.margin(1:4) = margin;
        end
        
        function doResize(obj, bounds)
            bounds(1:2) = bounds(1:2) + obj.margin(1:2);
            bounds(3:4) = bounds(3:4) - obj.margin(3:4) - obj.margin(1:2);

            set(obj.handle, 'Position', bounds);
            
            obj.doResize@GUIComponent(bounds);
        end

        function text = getText(obj)
            text = get(obj.handle, 'String');
        end
        
        function setText(obj, text)
            set(obj.handle, 'String', text);
        end
    end                
end