function pathstr = create_directories(varargin)
% CREATE_DIRECTORIES  Concatenates input arguments into
%  a path string and creates that directory if it didn't
%  already exist.

    pathstr = '';

    for i = 1:nargin
        pathstr = fullfile(pathstr, varargin{i});
        
        if(~exist(pathstr, 'dir'))
            mkdir(pathstr);
        end
    end
end