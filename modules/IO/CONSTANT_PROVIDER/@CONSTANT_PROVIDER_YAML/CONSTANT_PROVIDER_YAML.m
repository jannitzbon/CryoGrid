classdef CONSTANT_PROVIDER_YAML < CONSTANT_PROVIDER_base_class
    % Child class of CONSTANT_PROVIDER
    % The CONSTANT_PROVIDER_YAML will handle getting constants from a yml file.
    
    properties
        const_file
    end
    
    methods
        function self = CONSTANT_PROVIDER_YAML(mypath, const_file)
            % CONSTRUCTOR for CONSTANT_PROVIDER_YAML
            %   Reads in constants from constant file of type 'yml'.
            %
            %   ARGUMENTS:
            %   mypath:       path to constant file
            %   const_file:   filename of const_file

            self.const_file = const_file;
            const_data = ReadYaml([mypath '/' const_file]);
            self.const_data = const_data.CONST;
            self.source_type = 'yml';
            self.filepath = mypath;
        end

        
        function value = get_constant(self, name)
            % GET_CONSTANT  retrieves the value of a particular constant
            %   from the constant source
            %
            %   ARGUMENTS:
            %   name:  the name (string) of the constant to retrieve
            %
            %   RETURNS: 
            %   val:   the the value requested
            
            if ~ischar(name)
                % Do nothing if we are not passed a string name.
                return
            end
            
            % Extract relevant constant from the loaded source
            if isfield(self.const_data, name)
                value = self.const_data.(name);
            else
                error('Constant ' + name + ' not provided!')
            end
        end
         
        
        function structure = populate_struct(self, structure)
            % POPULATE_STRUCT  Populates the fields of the provided structure with
            %   values from the constant source (here yml file)
            %
            %   NOTICE: The index is here the actual index specified for a
            %     certain class in the yml file.
            %
            %   ARGUMENTS:
            %   structure:  a structure with empty fields to be populated
            %
            %   RETURNS: 
            %   structure:  the input structure with fields populated.
            
            if ~isstruct(structure)
                % Do nothing if we are not passed a proper structure.
                % Happens e.g. when CONST has no fields (empty)
                return
            end
            
            % Get list of fieldnames in the requested structure
            fn = fieldnames(structure);            
            fn_const_file = fieldnames(self.const_data);
            
            % Initialize cell array to hold names of fields to which values have been assigned
            assigned_fields = [];
            
            % Loop over all rows, and extract variables
            for i = 1:size(fn,1)
                if any(strcmp(fn{i}, fn_const_file))                 
                    structure.(fn{i}) = self.const_data.(fn{i});
                    % Add field name to assigned_fields
                    assigned_fields = [assigned_fields fn(i)];
                end
            end
            
            % Now loop over all field names in structure
            for i = 1:length(fn)
                if ~any(strcmp(assigned_fields, fn{i}))
                    % if this field was not yet assigned, look for a table that includes the field
                    st = dbstack;
                    warning(['!!! Table lookup in ' st.name ' is not yet implemented.']);
                end
            end                                 
        end
    end
end

