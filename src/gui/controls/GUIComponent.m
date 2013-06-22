classdef GUIComponent < EventProvider
    % GUICOMPONENT is the baseclass for all other Visual (GUI) Components
    % in the IDCC Library. It provides basic support for hierarchical
    % controls.
        
    properties(SetAccess = protected)
        % The parent of this component
        parent;
        
        % A cell array containing all children of this component
        children;
        
        % Stores the maximum amount of children
        maxChildren;
        
        % Current window (rectangle) assigned to this control
        % storing this allows for a (partial) redraw without
        % involving the top-level container.
        bounds;
        
        % Determines whether the component is visible
        visible;
    end
    
    methods(Access = public)
        % Construct an object without any children and without a parent
        function obj = GUIComponent()
            obj.parent = 0;
            obj.children = {};
            obj.maxChildren = 0;
            obj.visible = true;
        end
        
        
        function setVisible(obj, state)
            obj.visible = state;
            
            for i = 1:length(obj.children)
                obj.children{i}.parentVisibilityChanged()
            end
        end
        
        % Returns the (figure) handle of the top-level container
        function [h] = getParentHandle(obj)           
            if(isobject(obj.parent))
                h = obj.parent.getParentHandle();
            else
                h = 0;
            end
        end
        
        % Sets the parent of this container and makes sure we are
        % registered as a child of the parent
        function setParent(obj, parent)            
            if(isobject(obj.parent) && obj.parent ~= parent)
                obj.parent.removeComponent(obj);
            end

            if(isobject(parent) && ~parent.hasComponent(obj))
                parent.addComponent(obj);
            end
            
            obj.parent = parent;

            % Re-assign the parent of all children to allow for
            %  deferred object construction
            for i = 1:length(obj.children)
                obj.children{i}.setParent(obj);
            end            
        end
        
        % Removes a child-component
        function removeComponent(obj, child)
            for i = 1:length(obj.children)
                if(obj.children{i} == child)
                    obj.children{i} = [];
                    return;
                end
            end
        end
        
        % Checks whether a given component is a child
        function [res] = hasComponent(obj, child)
            res = 0;
            
            for i = 1:length(obj.children)
                if(obj.children{i} == child)
                    res = 1;
                    return;
                end
            end            
        end
        
        % Determines number of components
        function cnt = countComponents(obj)
            cnt = length(obj.children);
        end
        
        % Return component by id
        function cmp = getComponent(obj, id)
            cmp = obj.children{id};
        end
        
        % Add a component as a child and informs parent about it
        function addComponent(obj, child)
            % We are already a child, refresh and bail
            if(obj.hasComponent(child))
                child.setParent(obj);
                obj.doResize(obj.bounds);
                return;
            end
            
            % We are not a child, but we reached the maximum amount
            if(length(obj.children) >= obj.maxChildren)
                warning('DCC:GUIComponent:MaxChildrenReached', 'This control does not allow more children...');
                return;
            end
            
            % Add child and make sure parent knows about this
            obj.children{end + 1} = child;            
            child.setParent(obj);                       
            obj.doResize(obj.bounds);
        end

        % Returns the limits this control imposes on it's own size
        % a value of NaN denotes no limit. Entries are [W H]
        function [minimum, maximum] = getSizeConstraints(obj)
            minimum = [10 10];
            maximum = [Inf Inf];
        end        
        
        % To be called when a parent changes size
        function doResize(obj, bounds)
            obj.bounds = bounds;
            
            % Inform our children about this
            for i = 1:length(obj.children)
                obj.children{i}.doResize(bounds);
            end
        end
        
        function refresh(obj)
            obj.doResize(obj.bounds);
        end
        
        function parentVisibilityChanged(obj)
        end
    end
end