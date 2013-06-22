classdef GUITabContainer < GUIComponent
    
    methods(Access = public)
        function obj = GUITabContainer()
            obj = obj@GUIComponent;
            obj.maxChildren = Inf;
        end

        function switchTo(obj, id)
            n = obj.countComponents();
            
            if(id < 1 || id > n)
                error('DCC:GUI', 'Invalid tab identifier');
            end
            
            for i = 1:n
                if(id ~= i)
                    obj.getComponent(i).setVisible(0);
                end
            end
            
            obj.getComponent(id).setVisible(1);
        end
        
    end
end