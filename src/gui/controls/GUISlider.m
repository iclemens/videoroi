classdef GUISlider < GUIComponent
    
    properties
        handle;
        margin;

        value;
        minValue;
        maxValue;

        minorStep;
        majorStep;

        onChange;
    end
    
    methods
        function obj = GUISlider()
            obj = obj@GUIComponent();            
            obj.margin = [5 5 5 5];
            obj.handle = 0;
            obj.value = 0;
            obj.minValue = 0;
            obj.maxValue = 255;
            obj.minorStep = NaN;
            obj.majorStep = NaN;
            obj.onChange = {};
        end

        function doChange(obj)
            obj.invokeEventListeners('change');
        end
                
        function constructObject(obj)
            parentHandle = obj.getParentHandle();
            
            if(parentHandle ~= 0)            
                obj.handle = uicontrol('Parent', parentHandle, 'Style', 'slider', 'Units', 'pixels', 'Min', 0, 'Max', 255, 'Value', 0);                
                set(obj.handle, 'Callback', @(a, b) obj.doChange());
                
                obj.setValue(obj.value);
                obj.setBounds(obj.minValue, obj.maxValue);
                obj.setStepSize(obj.minorStep, obj.majorStep);
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
        
        function setValue(obj, value)
            obj.value = value;
            
            if(obj.handle)
                set(obj.handle, 'Value', obj.value);
            end
        end
        
        function value = getValue(obj)
            if(obj.handle)
                obj.value = get(obj.handle, 'Value');
            end

            value = obj.value;
        end
        
        function setStepSize(obj, minor, major)                    
          if nargin < 3
            major = 10 * minor;
          end
          
          obj.minorStep = minor;
          obj.majorStep = major;
          
          if obj.handle
            if isnan(obj.minorStep)
              minor = 0.01 * (obj.maxValue - obj.minValue);
            end
            
            if isnan(obj.majorStep)
              major = 0.1 * (obj.maxValue - obj.minValue);
            end

            stepSize = [minor major] / (obj.maxValue - obj.minValue);            
            stepSize = min(1, max(0, stepSize));            
            
            set(obj.handle, 'SliderStep', stepSize);
          end
        end        
        
        function setBounds(obj, minimum, maximum)
            obj.minValue = minimum;
            obj.maxValue = maximum;
            
            if(obj.handle)
                set(obj.handle, 'Min', obj.minValue);
                set(obj.handle, 'Max', obj.maxValue);
                obj.setStepSize(obj.minorStep, obj.majorStep);
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
                warning('DCC:GUISlider:NotEnoughSpace', 'Cannot resize control due to limited screen-space');
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