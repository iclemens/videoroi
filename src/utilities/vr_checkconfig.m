function cfg = vr_checkconfig(cfg, varargin)
% VR_CHECKCONFIG  Performs common tasks that ensure the validity of the
% configuration structure.

    % Make sure cfg is a sturcture
    if(~isstruct(cfg)), error('cfg should be a structure'); end;
    if mod(length(varargin), 2) == 1, error('invalid number of parameters'); end;
    
    for i = 1:2:length(varargin)        
        if(strcmp(varargin{i}, 'required'))            
            check_required(cfg, varargin{i + 1});
        elseif(strcmp(varargin{i}, 'renamed'))            
            cfg = rename_fields(cfg, varargin{i + 1});
        elseif(strcmp(varargin{i}, 'defaults'))
            cfg = set_defaults(cfg, varargin{i + 1});
        elseif(strcmp(varargin{i}, 'validate'))
            validate(cfg, varargin{i + 1});
        else
            error('invalid options "%s"', varargin{i});
        end        
    end;
    
    
    %%%%%%%%%%%%%%%%%%%%
    % Helper functions %
    %%%%%%%%%%%%%%%%%%%%
    
    
    function validate(cfg, validators)
        % Validates field contents
        
        if(~iscell(validators)), error('parameter to "validate" should be a cell array'); end;
        if(size(validators, 2) ~= 2), error('parameter to "validate" should have two columns'); end;
       
        for j = 1:size(validators, 1)
            if isfield(cfg, validators{j, 1})
                if ~validators{j, 2}(cfg.(validators{j, 1}))
                    error('validation failed for field "%s"', validators{j ,1});
                end
            end;
        end        
    end
    
    
    function cfg = set_defaults(cfg, defaults)
        % Initializes unset fields with defaults.
        
        if(~iscell(defaults)), error('parameter to "defaults" should be a cell array'); end;
        if(size(defaults, 2) ~= 2), error('parameter to "defaults" should have two columns'); end;
       
        for j = 1:size(defaults, 1)
            if ~isfield(cfg, defaults{j, 1})
                default = defaults{j, 2};
                
                if isa(default, 'function_handle')
                    default = default();
                end
                
                cfg.(defaults{j, 1}) = default;
            end;
        end        
    end
    
    
    function cfg = rename_fields(cfg, renamed)
       % Rename fields, first column in renamed specifies old names and
       % the second column the new names.
       
       if(~iscell(renamed)), error('parameter to "renamed" should be a cell array'); end;
       if(size(renamed, 2) ~= 2), error('parameter to "renamed" should have two columns'); end;
       
       for j = 1:size(renamed, 1)
           if isfield(cfg, renamed{j, 1})
               if isfield(cfg, renamed{j, 2})
                   error('cfg field "%s" has been renamed to "%s", but both have been specified', renamed{j, 1}, renamed{j, 2});
               end;
               
               cfg.(renamed{j, 2}) = cfg.(renamed{j, 1});
               cfg = rmfield(cfg, renamed{j, 1});
               
               warning('cfg field "%s" has been renamed to "%s"', renamed{j, 1}, renamed{j, 2});
           end;
       end
    end
    

    function check_required(cfg, required)
        
        % Raises an error if a required field is not present
        if(~iscell(required)), required = {required}; end;
        
        for j = 1:length(required)
            if(~isfield(cfg, required{j}))
                error('cfg does not contain field "%s"', required{j});
            end;
        end            
    end
end