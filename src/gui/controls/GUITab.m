classdef GUITab < GUIComponent
    properties(Access = private)
        name;
        
        handle;
    end
    
    methods(Access = public)
        function obj = GUITab(name)
            obj = obj@GUIComponent;
            obj.name = name;
            obj.visible = 0;
            obj.handle = 0;
            obj.maxChildren = 1;
        end
        
        function constructObject(obj)
            parentHandle = obj.parent.getParentHandle();            
            
            if(parentHandle ~= 0)
                if(obj.visible), visible = 'On'; else visible = 'Off'; end;
                obj.handle = uipanel('Parent', parentHandle, 'Visible', visible, 'Units', 'pixels', 'BorderType', 'beveledout');
            end
        end

        function setVisible(obj, state)
            obj.setVisible@GUIComponent(state);
            
            if(obj.handle)
                if(obj.visible)
                    set(obj.handle, 'Visible', 'On');
                else
                    set(obj.handle, 'Visible', 'Off');
                end
            end;
         end
        
        function setParent(obj, parent)
            obj.parent = parent;
            parentHandle = parent.getParentHandle();                       
            
            if(parentHandle ~= 0)
                if(~obj.handle), constructObject(obj); end;
                set(obj.handle, 'Parent', parentHandle);
            end
            
            obj.setParent@GUIComponent(parent);
        end  
        
        function handle = getParentHandle(obj)
            handle = obj.handle;
        end
        
        function doResize(obj, bounds)
            %bounds(1:2) = bounds(1:2) + obj.margin(1:2);
            %bounds(3:4) = bounds(3:4) - obj.margin(3:4) - obj.margin(1:2);

            %[minimum, maximum] = obj.getSizeConstraints();
            
            %if(bounds(3) < 0 || bounds(4) < 0 || bounds(3) < minimum(1) - obj.margin(3) - obj.margin(1) || bounds(4) < minimum(2) - obj.margin(2) - obj.margin(1))
                %warning('DCC:GUIButton:NotEnoughSpace', 'Cannot resize control due to limited screen-space');
                %set(obj.handle, 'Visible', 'Off');
                %return;
            %else
%                set(obj.handle, 'Visible', 'on');
 %           end
            
            if(obj.handle)
                set(obj.handle, 'Position', bounds);
            end;
            
            childBounds = bounds;
            
            if(~isempty(childBounds))
            
            childBounds(1:2) = 5;
            childBounds(3:4) = childBounds(3:4) - 10;
            
            obj.doResize@GUIComponent(childBounds);
            end
        end        
    end
end