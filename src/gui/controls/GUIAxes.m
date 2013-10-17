classdef GUIAxes < GUIComponent
  
  properties
    handle;
    margin;
    padding;
    
    onConstruction;
  end
  
  methods
    function obj = GUIAxes()
      obj = obj@GUIComponent();
      obj.margin = [5 5 5 5];
      obj.padding = [NaN NaN NaN NaN];
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
    
    function setPadding(obj, padding)
      obj.padding(1:4) = padding;
    end
    
    function doResize(obj, bounds)
      bounds(1:2) = bounds(1:2) + obj.margin(1:2);
      bounds(3:4) = bounds(3:4) - obj.margin(3:4) - obj.margin(1:2);
      
      set(obj.handle, 'OuterPosition', bounds);
      
      if all(~isnan(obj.padding))
        inner(1:2) = bounds(1:2) + obj.padding(1:2);
        inner(3:4) = bounds(3:4) - obj.padding(1:2) - obj.padding(3:4);
        set(obj.handle, 'Position', inner);
      end
      
      obj.doResize@GUIComponent(bounds);
    end
  end
end