classdef GUIWindow < GUIComponent
   
    properties
        handle;        
        position;
        title;
        
        resizeCallback;
    end
    
    methods
        function obj = GUIWindow()
            obj = obj@GUIComponent();            
            obj.handle = figure('Units', 'pixels', 'MenuBar', 'None', 'ToolBar', 'None', 'Name', 'GUI', 'DockControls', 'off', 'NumberTitle', 'off', 'Color', [240 240 240] / 255);
            obj.maxChildren = 1;
            
            obj.resizeCallback = @(a, b) obj.doResize(obj.position);
            
            set(obj.handle, 'ResizeFcn', obj.resizeCallback);
            set(obj.handle, 'KeyPressFcn', @(~, event) obj.doKeyPress(event));
            set(obj.handle, 'CloseRequestFcn', @(~, event) obj.closeCallback(event));
            
            obj.doResize(obj.position);
        end
        
        function setTitle(obj, title)
            obj.title = title;            
            set(obj.handle, 'Name', title);
        end
        
        function doKeyPress(obj, event)
            obj.invokeEventListeners('keyPress', event);
        end
        
        function closeCallback(obj, event)
            obj.invokeEventListeners('close');
            delete(obj.handle);
        end
        
        function doResize(obj, tmp)
            obj.position = get(obj.handle, 'Position');
            obj.position(1:2) = 0;
            
            obj.doResize@GUIComponent(obj.position);
        end
        
        function h = getParentHandle(obj)
            h = obj.handle;
        end
    end
    
end