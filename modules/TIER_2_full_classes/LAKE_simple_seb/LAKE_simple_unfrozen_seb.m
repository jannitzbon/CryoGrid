

classdef LAKE_simple_unfrozen_seb < SEB & HEAT_CONDUCTION & INITIALIZE

    
    methods
        % no constructor, always created from default constructor and initialize from LAKE_simple_seb class
        
        function self = LAKE_simple_unfrozen_seb(index, pprovider, cprovider, forcing)
            self@INITIALIZE(index, pprovider, cprovider, forcing);
        end
        
        function ground = initialize_from_LAKE_previous_season(ground, LAKE_simple_frozen)
            ground.PARA = LAKE_simple_frozen.PARA;
            ground.PARA.rs = 0;
            ground.CONST = LAKE_simple_frozen.CONST;
            ground.STATVAR = LAKE_simple_frozen.STATVAR;
            %change the STATVAR
            ground = merge_STATVAR(ground);
            ground.PARA.next_season_lake_class = class(LAKE_simple_frozen);
        end
        
        
        function ground = provide_PARA(ground)
            
            ground.PARA.albedo = [];
            ground.PARA.epsilon = [];
            ground.PARA.airT_height = []; %measurement height [m]
            ground.PARA.z0 = []; %roughness length [m]
            
            ground.PARA.area =[]; %initial area of the realization [m2]
            
            ground.PARA.heatFlux_lb = [];
            
            ground.PARA.dt_max = [] ; %[sec]
            ground.PARA.dE_max = []; %[J/m3]
            ground.PARA.next_season_lake_class = []; %class called by creation/annihilation IA class
        end
        
        function ground = provide_STATVAR(ground)
            
            ground.STATVAR.upperPos = [];
            ground.STATVAR.lowerPos = [];
            ground.STATVAR.layerThick = []; % [m]
            ground.STATVAR.area = []; %[m2]
            
            ground.STATVAR.waterIce = []; % [m]
            ground.STATVAR.mineral = []; % [m]
            ground.STATVAR.organic = []; % [m]
            ground.STATVAR.energy = [];  % [J/m2]
            
            ground.STATVAR.T = [];  % [degree C]
            ground.STATVAR.water = [];  % [m]
            ground.STATVAR.ice = [];
            ground.STATVAR.air = [];  % [m]
            ground.STATVAR.thermCond = [];
            
            ground.STATVAR.Lstar = [];
            ground.STATVAR.Qh = [];
            ground.STATVAR.Qe = [];
        end
    
        function ground = provide_CONST(ground)
            
            ground.CONST.L_f = [];
            
            ground.CONST.c_w = [];
            ground.CONST.c_o = [];

            
            ground.CONST.k_m = [];
            
            ground.CONST.sigma = []; %Stefan-Boltzmann constant
            ground.CONST.kappa = [];
            ground.CONST.L_s = []; %latent heat of vaporization
            
            ground.CONST.cp = [];
            ground.CONST.g = [];
            
            ground.CONST.rho_w = [];
            ground.CONST.rho_i = [];
        end
        
        
        function ground = merge_STATVAR(ground)  %merges all cell in one 
            ground.STATVAR.layerThick_store = ground.STATVAR.layerThick; %store the old grid, probably useful when going back to winter
            ground.STATVAR.layerThick = sum(ground.STATVAR.layerThick,1);
            
            ground.STATVAR.waterIce = sum(ground.STATVAR.waterIce,1);
            ground.STATVAR.mineral = sum(ground.STATVAR.mineral,1);
            ground.STATVAR.organic = sum(ground.STATVAR.organic,1);
            ground.STATVAR.energy = sum(ground.STATVAR.energy,1);
            ground.STATVAR.air = sum(ground.STATVAR.air,1);
            ground.STATVAR.area = mean(ground.STATVAR.area,1);
            
            ground = get_T_water_freeW(ground);
            ground.STATVAR.thermCond = ground.CONST.k_w;  %thermal conductivity of water
            
            ground.TEMP.d_energy = ground.STATVAR.energy.*0;
        end
        
        %----mandatory functions---------------
        
        %---time integration------
        
        function ground = get_boundary_condition_u(ground, forcing) %functions specific for individual class, allow changing from Dirichlet to SEB
            ground = surface_energy_balance(ground, forcing);
        end
        
        function ground = get_boundary_condition_l(ground, forcing)
             ground.TEMP.F_lb = forcing.PARA.heatFlux_lb .* ground.STATVAR.area(end);
             ground.TEMP.d_energy(end) = ground.TEMP.d_energy(end) + ground.TEMP.F_lb;
        end
        
        function ground = get_derivatives_prognostic(ground)
            ground.TEMP.d_energy = ground.TEMP.F_ub + ground.TEMP.F_lb;

        end
        
        function timestep = get_timestep(ground)  %could involve check for several state variables
           timestep = get_timestep_heat_coduction(ground);
        end
        
        function ground = advance_prognostic(ground, timestep) 
            %energy
            ground.STATVAR.energy = ground.STATVAR.energy + timestep .* ground.TEMP.d_energy;
        end
        
        function ground = compute_diagnostic_first_cell(ground, forcing)
            ground = L_star(ground, forcing);
        end
       
        function ground = compute_diagnostic(ground, forcing)
            
            ground = get_T_water_freeW(ground);
            
            ground.TEMP.d_energy = ground.STATVAR.energy.*0;
        end
        
        %shifts to frozen LAKE class
        function ground = check_trigger(ground, forcing)
            
            if ground.STATVAR.energy < 0  %freezing has started
                
                ia_create_next_season_lake = get_IA_class(class(ground), ground.PARA.next_season_lake_class); %delivers IA-class that creates and initializes the next season LAKE class
                lake_next_season = create_annihilate(ia_create_next_season_lake, ground);
                
                %lake_frozen = LAKE_simple_seb(-1,0,0,0);
                %lake_frozen = initialize_from_LAKE_unfrozen(lake_frozen, ground);
                
                %get the interaction classes from above and below
                lake_next_season.NEXT = ground.NEXT;
                lake_next_season.PREVIOUS = ground.PREVIOUS;
                lake_next_season.PREVIOUS.NEXT = lake_next_season;
                lake_next_season.NEXT.PREVIOUS = lake_next_season;
                %ground (CURRENT) still points to NEXT, so CURRENT.NEXT
                %will advance to the next - then it is
                %automatically handled by the garbage collection, since
                %there is no more pointer from any active variable to it
                
                %assemble new INTERACTIONS
                if ~strcmp(class(lake_next_season.PREVIOUS), 'Top')
                    ia_class = get_IA_class(class(lake_next_season.PREVIOUS), class(lake_next_season));
                    lake_next_season.IA_PREVIOUS = ia_class;
                    lake_next_season.IA_PREVIOUS.NEXT = lake_next_season;
                    lake_next_season.IA_PREVIOUS.PREVIOUS = lake_next_season.PREVIOUS;
                    lake_next_season.PREVIOUS.IA_NEXT = ia_class;
                end
                if ~strcmp(class(lake_next_season.NEXT), 'Bottom')
                    ia_class = get_IA_class(class(lake_next_season), class(lake_next_season.NEXT));
                    lake_next_season.IA_NEXT = ia_class;
                    lake_next_season.IA_NEXT.PREVIOUS = lake_next_season;
                    lake_next_season.IA_NEXT.NEXT = lake_next_season.NEXT;
                    lake_next_season.NEXT.IA_PREVIOUS = ia_class;
                end
                
                
            end
        end
        
        %-----non-mandatory functions-------
        function ground = surface_energy_balance(ground, forcing)
            ground.STATVAR.Lout = (1-ground.PARA.epsilon) .* forcing.TEMP.Lin + ground.PARA.epsilon .* ground.CONST.sigma .* (ground.STATVAR.T(1)+ 273.15).^4;
            ground.STATVAR.Sout = ground.PARA.albedo .*  forcing.TEMP.Sin;
            ground.STATVAR.Qh = Q_h(ground, forcing);
            ground.STATVAR.Qe = Q_eq(ground, forcing);
            
            ground.TEMP.F_ub = (forcing.TEMP.Sin + forcing.TEMP.Lin - ground.STATVAR.Lout - ground.STATVAR.Sout - ground.STATVAR.Qh - ground.STATVAR.Qe) .* ground.STATVAR.area(1);
            ground.TEMP.d_energy(1) = ground.TEMP.d_energy(1) + ground.TEMP.F_ub;
        end
        
        function ground = conductivity(ground)
            ground = conductivity_mixing_squares(ground);
        end
        

        
        %----inherited Tier 1 functions ------------
        
        function ground = get_derivative_energy(ground)
           ground = get_derivative_energy@HEAT_CONDUCTION(ground); 
        end
        
        function ground = conductivity_mixing_squares(ground)
            ground = conductivity_mixing_squares@HEAT_CONDUCTION(ground);
        end
        
        function flux = Q_h(ground, forcing)
           flux = Q_h@SEB(ground, forcing);
        end
    
        function flux = Q_eq(ground, forcing)
            flux = Q_eq@SEB(ground, forcing);
        end
        
        function timestep = get_timestep_heat_coduction(ground)
            timestep = get_timestep_heat_coduction@HEAT_CONDUCTION(ground);
        end
        
        function ground = L_star(ground, forcing)
           ground = L_star@SEB(ground, forcing); 
        end
        
        function ground = get_T_water_freeW(ground)
            ground = get_T_water_freeW@HEAT_CONDUCTION(ground);
        end
    end
    
end
