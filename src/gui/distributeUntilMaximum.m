function [allocated, leftover] = distributeUntilMaximum(amount, maximum)
    allocated = zeros(1, length(maximum));

    while(any(allocated <= maximum) && amount > 0)
        distrOver = allocated <= maximum;
        toAllocate = max(maximum(distrOver), floor(amount / sum(distrOver)));
        allocated(distrOver) = allocated(distrOver) + toAllocate;
        maximum = maximum - toAllocate;
        amount = amount - sum(toAllocate);
    end

    leftover = amount;
end