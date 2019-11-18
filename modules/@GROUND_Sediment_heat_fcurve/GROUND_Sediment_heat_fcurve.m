
%> GROUND_SEDIMENT_HEAT_FCURVE class for ground with sediment properties,
%> heat transfer and a freezing charackteristic curve based on measurements
%> 
%> different sediment types can be set using the properties for 
%> soilType, Salinity, fraction of Mineral and Organic Content, Porosity
classdef GROUND_Sediment_heat_fcurve < GROUND_base_class
    % MISSING
    % - initialization in dependence on lat/lon/zsb, forcing, flag for initial
    %   conditions, depth in the stratigraphy
    % - triggered sedimentation/erosion
    
%     properties %from the superclass
%         CONST %constants
%         PARA %external service parameters, all other
%         STATVAR  %energy, water content, etc.
%         TEMP  %derivatives in prognostic timestep and optimal timestep
%                 
%         PREVIOUS
%         NEXT
%         IA_PREVIOUS
%         IA_NEXT
%     end


    methods

        %mandatory functions for each class
             
        function ground = provide_variables(ground)  
            % initializes the subvariables as empty arrays
            ground = provide_variables@GROUND_base_class(ground);
            ground = provide_PARA(ground);
            ground = provide_CONST(ground);
            ground = provide_STATVAR(ground);
        end
        
        function variable = initialize_from_file(ground, variable, section)
            % read in parameters from file
            variable = initialize_from_file@GROUND_base_class(ground, variable, section);    
        end
        
        function ground = assign_global_variables(ground, forcing)
            % assigns ground heat flow from the forcing to the ground
            ground = assign_global_variables@GROUND_base_class(ground, forcing);
            
            ground.TEMP.T_ub = forcing.DATA.TForcing(1);
        end
        
        function ground = initialize_STATVAR_from_file(ground, grid, forcing, depths)
            %initialize layerThick, upperPos, lowerPos, etc in the superclass
            ground = initialize_STATVAR_from_file@GROUND_base_class(ground, grid, forcing, depths);
            ground.STATVAR.porosity = ground.STATVAR.water;

            ground = finalize_STATVAR(ground); %assign all variables, that must be calculated or assigned otherwise, including energy, water and ice contents, thermal conductivity
        end

        function ground = get_boundary_condition_u(ground, forcing) %functions specific for individual class, allow changing from Dirichlet to SEB
            %put dirichlet condition with forcing temperature here!
            %calculate resulting flux here
            T_ub = forcing.TEMP.TForcing;
            thermCond = ground.STATVAR.thermCond;
            layerThick = ground.STATVAR.layerThick;
            T = ground.STATVAR.T;

            ground.TEMP.T_ub = T_ub; %for conductivity
            ground.TEMP.heatFlux_ub = thermCond(1)*(T(1) - T_ub) / abs(layerThick(1)/2); %for spatial derivative

        end

        function ground = get_boundary_condition_l(ground, forcing)
            %put geoothermal heat flux here
            ground.TEMP.heatFlux_lb = ground.PARA.heatFlux_lb; %get_heatFlux_lb(ground);
        end


        function ground = get_derivatives_prognostic(ground)
            %spatial derivative
            ground.TEMP.divT = get_derivative_temperature_only(ground); %this gives a vector
        end

        function timestep = get_timestep(ground)  %could involve check for several state variables in seconds!
            %how do we calculate the next time step?
            %timestep = (max(abs(ground.TEMP.divT) ./ ground.STATVAR.layerThick));%*ground.CONST.year_sec;

            %timestep = ground.PARA.ridiculoushighnumber*sqrt(1/12* max(abs(ground.TEMP.divT))*max(ground.STATVAR.layerThick)^2);

            %timestep = 1/(max(abs(ground.TEMP.divT)./(ground.STATVAR.layerThick))); %estimate in seconds
            %timestep = sqrt(1/12* max(abs(ground.TEMP.divT))*max(ground.STATVAR.layerThick)^2); %estimate in seconds

            courant_number = min(1/2 * ground.STATVAR.c_eff./ground.STATVAR.thermCond(1:end-1) .* (ground.STATVAR.layerThick).^2);
            timestep = courant_number/(3600*24); %convert estimate from seconds to days

%             if timestep < 300 %days
%                 fprintf('timestep is %f days \n', timestep)
%             end

            %fprintf('timestep = %f, \ntimestep_2 = %f, \ndifference = %f \n', timestep, timestep_2, timestep-timestep_2)

        end

        function ground = advance_prognostic(ground, timestep) %real timestep derived as minimum of several classes in [days] here!
            timestep = timestep*(3600*24); %convert timestep from days to seconds
            %put advancing in time here
            ground.STATVAR.T = ground.STATVAR.T + timestep .* ground.TEMP.divT;
        end

        function ground = compute_diagnostic_first_cell(ground, forcing)
            %put stuff that happens only if this cell is the first cell
            %here
            %marine sedimentation could be happening here

            %What needs to happen here?

            %ground = L_star(ground, forcing);
        end

        function ground = compute_diagnostic(ground, forcing)
            %put stuff that happens in every cell here

            %update conductivity, heat capacity and liquid water content
            ground = getThermalProps_noSaltDiffusion(ground);

            %isostatic movement could happen here

            %What needs to happen here?
        end


    end
end
