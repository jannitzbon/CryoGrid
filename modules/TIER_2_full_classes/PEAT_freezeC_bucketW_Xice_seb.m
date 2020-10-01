

classdef PEAT_freezeC_bucketW_Xice_seb < SEB & HEAT_CONDUCTION & FREEZE_CURVE & WATER_FLUXES & INITIALIZE  %@ NITIN: add your Tier1 Peat class here

    
    methods
        
        function self = PEAT_freezeC_bucketW_Xice_seb(index, pprovider, cprovider, forcing)  
            self@INITIALIZE(index, pprovider, cprovider, forcing);
        end
        
        function ground = provide_CONST(ground)
            
            ground.CONST.L_f = [];
            ground.CONST.Tmfw = [];
            
            ground.CONST.c_w = [];
            ground.CONST.c_i = [];
            ground.CONST.c_o = [];
            ground.CONST.c_m = [];
            
            ground.CONST.k_a = [];       %air [Hillel(1982)]
            ground.CONST.k_w = [];        %water [Hillel(1982)]
            ground.CONST.k_i = [];         %ice [Hillel(1982)]
            ground.CONST.k_o = [];        %organic [Hillel(1982)]
            ground.CONST.k_m = [];
            
            ground.CONST.sigma = []; %Stefan-Boltzmann constant
            ground.CONST.kappa = [];
            ground.CONST.L_s = []; %latent heat of vaporization
            
            ground.CONST.cp = [];
            ground.CONST.g = [];
            
            ground.CONST.rho_w = [];
            ground.CONST.rho_i = [];
            
            %Mualem Van Genuchten model
            ground.CONST.alpha_sand = [];
            ground.CONST.alpha_silt = [];
            ground.CONST.n_sand = [];
            ground.CONST.n_silt = [];
            ground.CONST.residual_wc_sand = [];
            ground.CONST.residual_wc_silt = [];

        end
        
        function ground = provide_PARA(ground)
            
            ground.PARA.albedo = [];
            ground.PARA.epsilon = [];
            ground.PARA.airT_height = []; %measurement height [m]
            ground.PARA.z0 = []; %roughness length [m]
            
            ground.PARA.area =[]; %initial area of the realization [m2]
            
            ground.PARA.rootDepth = [];
            ground.PARA.evaporationDepth = [];
            ground.PARA.ratioET = [];
            
            ground.PARA.hydraulicConductivity = []; %change to a prametrization later?
            ground.PARA.externalWaterFlux = [] ; %external water flux added
            
            ground.PARA.heatFlux_lb = [];
            
            ground.PARA.dt_max = [] ; %[sec]
            ground.PARA.dE_max = []; %[J/m3]

            ground.PARA.LUT_size_waterIce = [];
            ground.PARA.LUT_size_T = [];
            ground.PARA.min_T = []; %minimum an maximum values for which the LUT is calculated (only roughly)
            ground.PARA.min_waterIce = [];
            ground.PARA.max_waterIce = [];
            ground.PARA.min_mineral_organic = [];

            %trigger parameters
            ground.PARA.threshold_Xwater = 0.05;
            %ground.PARA.threshold_Xwater_class = [];
            ground.PARA.threshold_Xwater_class = 'LAKE_simple_bucketW_seb_snow';  %default trigger if empty (this ensures stable run) 
            %otherwise interaction class trigger, must correspond to a sleeping class in the initialization!
            ground.PARA.threshold_Xwater_index = 1;
            
        end
        
        function ground = provide_STATVAR(ground)
            
            ground.STATVAR.upperPos = [];
            ground.STATVAR.lowerPos = [];
            ground.STATVAR.layerThick = []; % [m]
            
            ground.STATVAR.waterIce = []; % [m]
            ground.STATVAR.XwaterIce = [];
            ground.STATVAR.mineral = []; % [m]
            ground.STATVAR.organic = []; % [m]
            ground.STATVAR.energy = [];  % [J/m2]
            ground.STATVAR.soil_type = [];
                        
            ground.STATVAR.T = [];  % [degree C]
            ground.STATVAR.water = [];  % [m]
            ground.STATVAR.waterPotential = []; % [m]
            ground.STATVAR.Xwater = [];
            ground.STATVAR.Xice = [];
            ground.STATVAR.ice = [];
            ground.STATVAR.air = [];  % [m]
            ground.STATVAR.thermCond = [];
            
            ground.STATVAR.Lstar = [];
            ground.STATVAR.Qh = [];
            ground.STATVAR.Qe = [];
            
            ground.STATVAR.field_capacity = [];
            ground.STATVAR.excessWater = 0;
            
        end
        
        %----mandatory functions---------------
        %----initialization--------------------
        
        function ground = finalize_init(ground, forcing) %assign all variables, that must be calculated or assigned otherwise for initialization
            ground.PARA.heatFlux_lb = forcing.PARA.heatFlux_lb;
            ground.PARA.airT_height = forcing.PARA.airT_height;
            ground.STATVAR.area = forcing.PARA.area + ground.STATVAR.T .* 0;
            
            %add more in case clay becomes relevant
            ground.CONST.vanGen_alpha = [ground.CONST.alpha_sand ground.CONST.alpha_silt];
            ground.CONST.vanGen_n = [ground.CONST.n_sand ground.CONST.n_silt];
            ground.CONST.vanGen_residual_wc = [ground.CONST.residual_wc_sand ground.CONST.residual_wc_silt];
            
            ground = get_E_freezeC_Xice(ground);
            ground = conductivity(ground);
            
            ground = create_LUT_freezeC(ground);

            ground.STATVAR.Lstar = -100;
            ground.STATVAR.Qh = 0;
            ground.STATVAR.Qe = 0;
            
            ground = set_TEMP_2zero(ground);
            
            
            %@NITIN: add your initialization routine here. Make sure all
            %the arrays have the same lengths as the STATVAR's produced by the code, so for example ground.STATVAR.C_Content = ground.STATVAR.T .* 0; 
        end
        
        %---time integration------
        
        function ground = get_boundary_condition_u(ground, forcing) %functions specific for individual class, allow changing from Dirichlet to SEB
      
            ground = surface_energy_balance(ground, forcing);
            ground = get_boundary_condition_u_water_Xice(ground, forcing); %checked that this flux can be taken up!!
            
%             %@NITIN: add your upper boundary codition here, this should
%             update TEMP variables
%             if ground.TEMP.timestep_PEAT >= ground.PARA.target_timestep_PEAT
%                 ground = get_boundary_condition_u_PEAT(ground, forcing);
%             end
        end
        
        function [ground, S_up] = penetrate_SW(ground, S_down)  %mandatory function when used with class that features SW penetration
            [ground, S_up] = penetrate_SW_no_transmission(ground, S_down);
        end
        
        function ground = get_boundary_condition_l(ground, forcing)
             ground.TEMP.F_lb = forcing.PARA.heatFlux_lb .* ground.STATVAR.area(end);
             ground.TEMP.d_energy(end) = ground.TEMP.d_energy(end) + ground.TEMP.F_lb;
             ground = get_boundary_condition_l_water2(ground);  %if flux not zero, check that the water flowing out is available! Not implemented here.
        end
        
        function ground = get_derivatives_prognostic(ground)
            ground = get_derivative_energy(ground);
            ground = get_derivative_water_Xice(ground); %normal downward water flow in matrix
            ground = get_derivative_Xwater(ground); %upward flow of Xwater
            
            %@NITIN: add your get_derivatives here, this should
%             update TEMP variables
%             if ground.TEMP.timestep_PEAT >= ground.PARA.target_timestep_PEAT
%                 ground = get_derivative_PEAT(ground);
%             end

        end
        
        function timestep = get_timestep(ground)  %could involve check for several state variables
           timestep = get_timestep_heat_coduction(ground);
           timestep = min(timestep, get_timestep_water(ground)); 
           %@NITIN: update the long peat timestep  
           %ground.TEMP.timestep_PEAT = ground.TEMP.timestep_PEAT + timestep;
        end
        
        function ground = advance_prognostic(ground, timestep) 
            %energy
            ground.STATVAR.energy = ground.STATVAR.energy + timestep .* ground.TEMP.d_energy;
            ground.STATVAR.energy = ground.STATVAR.energy + timestep .* ground.TEMP.d_water_energy + ground.TEMP.d_Xwater_energy; %add energy from water advection
            %water
            ground.STATVAR.waterIce = ground.STATVAR.waterIce + timestep .* ground.TEMP.d_water; %subtract water from ET
            ground.STATVAR.XwaterIce = ground.STATVAR.XwaterIce + timestep .* ground.TEMP.d_Xwater;
            ground.STATVAR.XwaterIce(ground.STATVAR.XwaterIce<0) = 0; %remove rounding errors

            ground.STATVAR.layerThick = ground.STATVAR.layerThick + timestep .* ground.TEMP.d_Xwater ./ ground.STATVAR.area;

             %@NITIN: add your advance_prognostic here, using the long
             %timestep, update also energy, water, etc.
%             if ground.TEMP.timestep_PEAT >= ground.PARA.target_timestep_PEAT
%                 ground.STATVAR.C_content = ground.STATVAR.C_content + ground.TEMP.timestep_PEAT .* ground.TEMP.C_derivative;
%                 ground.STATVAR.energy = ...
%                     ground.STATVAR.layerThick = ...
%             end
            
            
        end
        
        function ground = compute_diagnostic_first_cell(ground, forcing)
            ground = L_star(ground, forcing);
        end
       
        function ground = compute_diagnostic(ground, forcing)
            %@NITIN: add your diagnostic step here, potential
            %regridding would go here, possibly move excess water to
            %XwaterIce
            %if   ground.TEMP.timestep_PEAT >= ground.PARA.target_timestep_PEAT
            %      ground.TEMP.timestep_PEAT = 0; %reset to zero
            %end
            
            
            %equilibrate water between matrix and Xwater within cells
            air = ground.STATVAR.layerThick .* ground.STATVAR.area - ground.STATVAR.XwaterIce - ground.STATVAR.waterIce - ground.STATVAR.mineral - ground.STATVAR.organic; 
            move_cells = (ground.STATVAR.Xwater > 0) & (air > 0);
            move_Xwater = min(ground.STATVAR.Xwater(move_cells), air(move_cells));
            ground.STATVAR.XwaterIce(move_cells) = ground.STATVAR.XwaterIce(move_cells) - move_Xwater;
            ground.STATVAR.waterIce(move_cells) = ground.STATVAR.waterIce(move_cells) + move_Xwater;
            ground.STATVAR.layerThick(move_cells) = ground.STATVAR.layerThick(move_cells) - move_Xwater ./  ground.STATVAR.area(move_cells);
            
            ground.STATVAR.layerThick = max(ground.STATVAR.layerThick, ...
                (ground.STATVAR.XwaterIce + ground.STATVAR.waterIce + ground.STATVAR.mineral + ground.STATVAR.organic) ./ ground.STATVAR.area);  %prevent rounding errors, would lead to wrong sign water fluxes in next prognostic step
           
            
            ground = get_T_water_freezeC_Xice(ground); %this gets the intensive variables (T, ect. if the extensive variables are updated)
            
            ground = conductivity(ground);
            
            ground = set_TEMP_2zero(ground);
        end
        
        function ground = check_trigger(ground, forcing)
            trigger_yes_no = 0;
            %water overtopping first cell
            if isequal(class(ground.PREVIOUS), 'Top') && ground.STATVAR.Xwater(1) > ground.PARA.threshold_Xwater .* ground.STATVAR.area(1) % no snow cover and too much Xwater
                                
                if isempty(ground.PARA.threshold_Xwater_class) %default, remove water from first cell, otherwise the Q_e calculation crashes
                    remove_first_cell = max(0, ground.STATVAR.Xwater(1) - ground.PARA.threshold_Xwater .* ground.STATVAR.area(1));
                    ground.STATVAR.XwaterIce(1) = ground.STATVAR.XwaterIce(1) - remove_first_cell;
                    ground.STATVAR.layerThick(1) = ground.STATVAR.layerThick(1) - remove_first_cell ./ ground.STATVAR.area(1);
                    ground.STATVAR.energy(1) = ground.STATVAR.energy(1) - remove_first_cell .* ground.STATVAR.T(1) .* ground.CONST.c_w;
                    ground.STATVAR.excessWater = ground.STATVAR.excessWater + remove_first_cell;  %water must be removed laterally for runoff output, otherwise it accumulates
                else
                    trigger_class = get_IA_class(ground.PARA.threshold_Xwater_class, class(ground));
                    trigger_create_LAKE(trigger_class, ground, forcing); %creates a new class and does all the rearranging of the stratigraphy (I hope!)
                    
                    trigger_yes_no = 1; %can be used to prevent several triggers ocurring in one timestep, like create a lake and create snow simulataneously
                end
            end
        end
        
        
        %-----non-mandatory functions-------
        function ground = set_TEMP_2zero(ground)
            ground.TEMP.d_energy = ground.STATVAR.energy.*0;
            ground.TEMP.d_water = ground.STATVAR.energy.*0;
            ground.TEMP.d_water_ET = ground.STATVAR.energy.*0;
            ground.TEMP.d_water_energy = ground.STATVAR.energy.*0;
            ground.TEMP.d_water_ET_energy = ground.STATVAR.energy.*0;
            ground.TEMP.d_Xwater = ground.STATVAR.energy.*0;
            ground.TEMP.d_Xwater_energy = ground.STATVAR.energy.*0;
            
             %@NITIN: add TEMP fields for your dervatives here, this sets
             %everything to zero for the next timestep
        end
        
        function ground = surface_energy_balance(ground, forcing)
            ground.STATVAR.Lout = (1-ground.PARA.epsilon) .* forcing.TEMP.Lin + ground.PARA.epsilon .* ground.CONST.sigma .* (ground.STATVAR.T(1)+ 273.15).^4;
            ground.STATVAR.Sout = ground.PARA.albedo .*  forcing.TEMP.Sin;
            ground.STATVAR.Qh = Q_h(ground, forcing);
            ground.STATVAR.Qe_pot = Q_eq_potET(ground, forcing);

            ground = calculateET_Xice(ground);
            
            ground.TEMP.F_ub = (forcing.TEMP.Sin + forcing.TEMP.Lin - ground.STATVAR.Lout - ground.STATVAR.Sout - ground.STATVAR.Qh - ground.STATVAR.Qe) .* ground.STATVAR.area(1);
            ground.TEMP.d_energy(1) = ground.TEMP.d_energy(1) + ground.TEMP.F_ub;
        end
        
        function ground = conductivity(ground)
            ground = conductivity_mixing_squares_Xice(ground);
        end
        
        
        %lateral fluxes---------------------------
        function ground = lateral_push_remove_surfaceWater(ground, lateral)
            ground = lateral_push_remove_surfaceWater_Xice(ground, lateral);
        end
        
        function ground = lateral_push_remove_subsurfaceWater(ground, lateral)
            ground = lateral_push_remove_subsurfaceWater_simple(ground, lateral);
        end
        
        
        %----inherited Tier 1 functions ------------
        
        function ground = get_derivative_energy(ground)
           ground = get_derivative_energy@HEAT_CONDUCTION(ground); 
        end
        
        function ground = conductivity_mixing_squares_Xice(ground)
            ground = conductivity_mixing_squares_Xice@HEAT_CONDUCTION(ground);
        end
        
        function flux = Q_h(ground, forcing)
           flux = Q_h@SEB(ground, forcing);
        end
    
        function flux = Q_eq_potET(ground, forcing)
            flux = Q_eq_potET@SEB(ground, forcing);
        end
        
        function ground = calculateET(ground)
            ground = calculateET@SEB(ground);
        end
        
        function ground = get_boundary_condition_u_water2(ground, forcing)
           ground = get_boundary_condition_u_water2@WATER_FLUXES(ground, forcing);
        end
        function ground = get_derivative_water2(ground)
            ground = get_derivative_water2@WATER_FLUXES(ground);
        end
        
        function timestep = get_timestep_heat_coduction(ground)
            timestep = get_timestep_heat_coduction@HEAT_CONDUCTION(ground);
        end
        
        function timestep = get_timestep_water(ground)
            timestep = get_timestep_water@WATER_FLUXES(ground);
        end
        
        function ground = L_star(ground, forcing)
           ground = L_star@SEB(ground, forcing); 
        end
        
        function [ground, S_up] = penetrate_SW_no_transmission(ground, S_down)
            [ground, S_up] = penetrate_SW_no_transmission@SEB(ground, S_down);
        end
        
        function ground = get_T_water_freeW(ground)
            ground = get_T_water_freeW@HEAT_CONDUCTION(ground);
        end
    end
    
end
