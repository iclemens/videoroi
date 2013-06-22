classdef GUIList < GUIComponent
    
    properties
        handle;
        margin;

        items;
        
        onClick;
    end
    
    methods
        function obj = GUIList()
            obj = obj@GUIComponent();            
            obj.margin = [5 5 5 5];
            obj.handle = 0;          
            obj.onClick = {};
            obj.items = {};
        end

        function doClick(obj)
            for i = 1:length(obj.onClick)
                obj.onClick{i}(obj);
            end
        end
        
        function addEventListener(obj, event, callback)
            if(strcmp(event, 'click'))
                obj.onClick{end + 1} = callback;
            end
        end
        
        function addItem(obj, item)
            obj.items{end + 1} = item;
            
            if(obj.handle)
                set(obj.handle, 'String', obj.items);
                
                if(length(obj.items) == 1)
                    set(obj.handle, 'Value', 1);
                end
            end
        end
        
        function clear(obj, item)
            obj.items = {};
            
            if(obj.handle)
                set(obj.handle, 'String', obj.items);
            end
        end
        
        function [idx] = getSelectedIndex(obj)
            idx = get(obj.handle, 'Value');
        end
        
        function val = getValueAtIndex(obj, idx)
            val = obj.items{idx};
        end
        
        function constructObject(obj)
            parentHandle = obj.getParentHandle();
            
            if(parentHandle ~= 0)            
                obj.handle = uicontrol('Parent', parentHandle, 'Style', 'listbox', 'Units', 'pixels', 'BackgroundColor', [1 1 1]);
                set(obj.handle, 'String', obj.items);
                set(obj.handle, 'Callback', @(a, b) obj.doClick());
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
        
        function setLabel(obj, label)
            obj.label = label;
            
            if(obj.handle)
                set(obj.handle, 'String', obj.label);
            end
        end

       function [minimum, maximum] = getSizeConstraints(obj)
            minimum = [50 + obj.margin(1) + obj.margin(3) 10 + obj.margin(2) + obj.margin(4)];
            maximum = [Inf 25 + obj.margin(2) + obj.margin(4)];
       end
        
        function doResize(obj, bounds)
            bounds(1:2) = bounds(1:2) + obj.margin(1:2);
            bounds(3:4) = bounds(3:4) - obj.margin(3:4) - obj.margin(1:2);

            [minimum, maximum] = obj.getSizeConstraints();
            
            if(bounds(3) < 0 || bounds(4) < 0 || bounds(3) < minimum(1) - obj.margin(3) - obj.margin(1) || bounds(4) < minimum(2) - obj.margin(2) - obj.margin(1))
                warning('DCC:GUIButton:NotEnoughSpace', 'Cannot resize control due to limited screen-space');
                set(obj.handle, 'Visible', 'Off');
                return;
            else
                set(obj.handle, 'Visible', 'on');
            end
            
            set(obj.handle, 'Position', bounds);
            
            obj.doResize@GUIComponent(bounds);
        end
    end                
end