classdef GUITabPanel < GUIComponent
    properties(Access = private)
        toggleArray;
        tabPanels;
    end
    
    methods(Access = public)
        function obj = GUITabPanel()
            obj = obj@GUIComponent;
            obj.maxChildren = Inf;
            
            verticalSplit = GUIBoxArray();
            verticalSplit.setVerticalDistribution([20 NaN]);
            obj.addComponent(verticalSplit);
            
            obj.toggleArray = GUIBoxArray();
            obj.toggleArray.setHorizontalDistribution(NaN);
            obj.toggleArray.setMargin([10 0 0 0]);
            
            obj.tabPanels = GUITabContainer();
            
            verticalSplit.addComponent(obj.toggleArray);
            verticalSplit.addComponent(obj.tabPanels);
        end
                      
        function tab = addTab(obj, name)
            n = obj.toggleArray.countComponents() + 1;
            
            toggleButton = GUIToggleButton(name);
            toggleButton.setMargin([0 0 0 0]);
            
            toggleButton.addEventListener('click', ...
                @(tmp) obj.switchTo(n));
            
            tab = GUITab(name);
            
            obj.toggleArray.setHorizontalDistribution(75 * ones(1, n));
            obj.toggleArray.addComponent(toggleButton);            
            obj.tabPanels.addComponent(tab);
            
            if(n == 1)
                obj.switchTo(1);
            end
        end
        
        
        function switchTo(obj, id)
            obj.tabPanels.switchTo(id);
            
            n = obj.toggleArray.countComponents();
            for i = 1:n
                if(i ~= id)
                    obj.toggleArray.getComponent(i).setValue(0);
                end
            end
            obj.toggleArray.getComponent(id).setValue(1);
        end
        
    end
end