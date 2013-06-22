classdef GUIBoxArray < GUIComponent
    % GUIBOXARRAY represents a matrix of controls
    
    properties 
        % The margin of the control, i.e. how much space is reserved around
        % the control.
        margin;
        
        % Determines how the controls are distributed over the available
        % space. NaN entries cause the dimensions to be determined
        % automatically. Otherwise, fractions of the total have to be
        % present. If the sum exceeds 1 a warning is displayed.
        
        verticalDistribution;
        horizontalDistribution;
    end
    
    methods
        function obj = GUIBoxArray()
            obj = obj@GUIComponent();            
            obj.margin = [5 5 5 5];            
            
            obj.verticalDistribution = 1;
            obj.horizontalDistribution = 1;
            
            obj.maxChildren = 1;
        end
        
        % Sets the 
        function setVerticalDistribution(obj, distribution)
            maxChildren = length(distribution) * length(obj.verticalDistribution);
            
            if(length(obj.children) > maxChildren)
                warning('DCC:GUIBoxArray:TooMuchChildren', 'Cannot change vertical distribution, too much children');
                return;
            end
            
            obj.verticalDistribution = distribution;            
            obj.maxChildren = maxChildren;
        end

        function setHorizontalDistribution(obj, distribution)
            maxChildren = length(distribution) * length(obj.horizontalDistribution);
            
            if(length(obj.children) > maxChildren)
                warning('DCC:GUIBoxArray:TooMuchChildren', 'Cannot change horizontal distribution, too much children');
                return;
            end
            
            obj.horizontalDistribution = distribution;
            obj.maxChildren = maxChildren;            
        end
        
        function [minimum, maximum] = getSizeConstraints(obj)
            [minWidths, maxWidths, minHeights, maxHeights] = obj.gatherChildConstraints();
            
            minimum = [nansum(minWidths) nansum(minHeights)];
            maximum = [nansum(maxWidths) nansum(maxHeights)];
            
            if(any(isnan(maxWidths)) || any(isinf(maxWidths)))
                maximum(1) = Inf;
            end
            
            if(any(isnan(maxHeights)) || any(isinf(maxHeights)))
                maximum(2) = Inf;
            end            
        end
        
        function setMargin(obj, margin)
            obj.margin(1:4) = margin;
        end
        
        function [minWidths, maxWidths, minHeights, maxHeights] = gatherChildConstraints(obj)
            n_columns = size(obj.horizontalDistribution, 2);
            n_rows = size(obj.verticalDistribution, 2);            
            
            minWidths = nan(1, n_columns);
            maxWidths = nan(1, n_columns);
            
            minHeights = nan(1, n_rows);
            maxHeights = nan(1, n_rows);
            
            for row = 1:n_rows
                for col = 1:n_columns
                    o_idx = (n_rows - row) * n_columns + col;
                                        
                    if(length(obj.children) >= o_idx)
                        [minimum, maximum] = obj.children{o_idx}.getSizeConstraints();
                        
                        if(isnan(minWidths(col)) || minWidths(col) < minimum(1))
                            minWidths(col) = minimum(1);
                        end
                        
                        if(isnan(minHeights(row)) || minHeights(row) < minimum(2))
                            minHeights(row) = minimum(2);
                        end
                        
                        if(isnan(maxWidths(col)) || maxWidths(col) < maximum(1))
                            maxWidths(col) = maximum(1);
                        end
                        
                        if(isnan(maxHeights(row)) || maxHeights(row) < maximum(2))
                            maxHeights(row) = maximum(2);
                        end
                        
                    end
                end
            end              
        end
        
        function doResize(obj, bounds)
            if(length(bounds) < 4)
                return;
            end
            
            obj.bounds = bounds;
            
            bounds(1:2) = bounds(1:2) + obj.margin(1:2);
            bounds(3:4) = bounds(3:4) - obj.margin(3:4) - obj.margin(1:2);

            n_columns = size(obj.horizontalDistribution, 2);
            n_rows = size(obj.verticalDistribution, 2);
           
            % Determine width and height as specified in distributions
            if(nansum(obj.horizontalDistribution) > 1)
                requestedWidths = obj.horizontalDistribution;
            else
                requestedWidths = obj.horizontalDistribution * bounds(3);
            end
            
            if(nansum(obj.verticalDistribution) > 1)
                requestedHeights = rev(obj.verticalDistribution);
            else
                requestedHeights = rev(obj.verticalDistribution) * bounds(4);
            end
            
            % Gather size constraints for each of the controls
            [minWidths, maxWidths, minHeights, maxHeights] = obj.gatherChildConstraints();

            if(nansum(obj.verticalDistribution) > 1)
                maxHeights = requestedHeights;
            end            
            
            if(nansum(obj.horizontalDistribution) > 1)
                maxWidths = requestedWidths;
            end
            
            availableWidth = bounds(3);
            availableHeight = bounds(4);
                        
            allocatedHeight = distribute(availableHeight, minHeights, requestedHeights, maxHeights);
            allocatedWidth = distribute(availableWidth, minWidths, requestedWidths, maxWidths);
            
            for row = 1:n_rows
                for col = 1:n_columns
                    o_idx = (n_rows - row) * n_columns + col;
                    
                     cellBounds = [...
                         bounds(1) + sum(allocatedWidth(1:col-1))
                         bounds(2) + sum(allocatedHeight(1:row-1))
                         allocatedWidth(col)
                         allocatedHeight(row)]';
                                         
                     if(length(obj.children) >= o_idx)
                         obj.children{o_idx}.doResize(cellBounds);
                     end
                 end
             end                
        end
    end                
end