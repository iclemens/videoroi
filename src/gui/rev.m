function m = rev(x)
    %
    % Reverses a vector such that
    %  [X Y Z] becomes [Z Y X]
    %
    % @author Ivar Clemens
    %
    
    if(nargin < 1)
        error('At least one input argument is required.');
    end
    
    m = x(end:-1:1);
end