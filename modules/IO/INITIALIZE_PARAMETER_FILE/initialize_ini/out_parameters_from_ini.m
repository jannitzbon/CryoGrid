
function out = out_parameters_from_ini(path_to_config_directory, available_class_names)
% This function creates the out object, reads the values from the ini
% configuration file and initializes the main variables. Also calls
% several functions to check the validity of the inputs.

 % Ini parser importing the parameters' values from the configuration file and storing them into a
    % structure
    ini = ini2struct([path_to_config_directory '\OUT.ini']);
    % Checking the validity and range of the inputs from the ini file
    out_ini_inputs_check(ini);
    
    % Extracting class name from the section header of the configuration file
    ini_class_name = cell2mat(fieldnames(ini));
    % Checking whether  the class exists within the model's folder structure
    class_exists(ini_class_name, available_class_names);
    
    % Creating the corresponding object from class cited in the
    % configuration file
    class_handle = str2func(ini_class_name);
    out = class_handle();
    out = provide_variables(out);
    
    % Initialization with the configuration file parameters
    out = initialize_from_ini(out, ini);

end



