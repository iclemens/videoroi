classdef EventProvider < handle
    properties(Access = private)
        eventNames = {};
        eventHandlers = {};
    end
    
    methods(Access = protected)
        %
        % Invokes an event listener
        %
        % @param event Name of the event to invoke listeners for
        % @param ... Zero or more parameters to pass to the callback
        %
        function invokeEventListeners(obj, event, varargin)
            idx = find(strcmp(obj.eventNames, event));
            
            if(isempty(idx)), return; end;
            
            for i = 1:length(obj.eventHandlers{idx})
                obj.eventHandlers{idx}{i}(obj, varargin{:});
            end
        end        
    end
    
    methods(Access = public)
        %
        % Register a handler for an event
        %
        % @param event Name of the event to register handler for
        % @param callback Function to call when the event fires
        %
        function addEventListener(obj, event, callback)
            idx = find(strcmp(obj.eventNames, event));
            
            if(isempty(idx))
                obj.eventNames{end + 1} = event;
                obj.eventHandlers{end + 1} = {};
                
                idx = length(obj.eventNames);
            end

            obj.eventHandlers{idx}{end + 1} = callback;
        end
    end
end