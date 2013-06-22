function [allocated, leftover] = distribute(amount, minimum, optimal, maximum)
    % Distributes available width or height amongst various controls.
    %
    %  amount - Amount of the resource to distribute
    %  minimum - Minimum size per control
    %  optimal - Optimal size per control
    %  maximum - Maximum size per control
    %

    optimal(isnan(optimal)) = minimum(isnan(optimal));

    [allocatedMin, amount] = distributeUntilMininum(amount, minimum);
    [allocatedOpt, amount] = distributeUntilMininum(amount, optimal - minimum);
    [allocatedMax, amount] = distributeUntilMininum(amount, maximum - optimal);
        
    rest = zeros(1, length(maximum));
    rest(isnan(maximum)) = Inf;
    
    [allocatedRest, amount] = distributeUntilMininum(amount, rest);
    
    allocated = allocatedMin + allocatedOpt + allocatedMax + allocatedRest;
    
    leftover = amount;   
end