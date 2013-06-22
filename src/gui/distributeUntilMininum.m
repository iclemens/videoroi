function [allocated, leftover] = distributeUntilMininum(amount, minimum)
    % Evenly distributes available space until the minimum requirements
    % for each control have been met.

    allocated = zeros(1, length(minimum));

    cycle = 0;
    
    while(any(allocated < minimum) && amount > 0)
        cycle = cycle + 1;
        
        if(cycle > 100)
            error('Error');
        end;
               
        distrOver = allocated < minimum;                        
        toAllocate = min(minimum(distrOver), floor(amount / sum(distrOver)));
        
        if(sum(toAllocate) == 0)
            tmp = find(distrOver);
            toAllocate(tmp(1)) = 1;
        end
        
        allocated(distrOver) = allocated(distrOver) + toAllocate;
        minimum(distrOver) = minimum(distrOver) - toAllocate;
        amount = amount - sum(toAllocate);
    end

    leftover = amount;
end