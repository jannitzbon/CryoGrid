

classdef GROUND_fcSimple_salt_seb < SEB & HEAT_CONDUCTION & SALT & HEAT_FLUXES_LATERAL & INITIALIZE
    
    
    methods
        
        function self = GROUND_fcSimple_salt_seb(index, pprovider, cprovider, forcing)
            self@INITIALIZE(index, pprovider, cprovider, forcing);
        end
        
        function ground = provide_PARA(ground)
            
            ground.PARA.albedo = [];
            ground.PARA.epsilon = [];
            ground.PARA.airT_height = []; %measurement height [m]
            ground.PARA.z0 = []; %roughness length [m]
            
            ground.PARA.area =[]; %initial area of the realization [m2]
            
            ground.PARA.rs = [];
            
            ground.PARA.heatFlux_lb = [];
            
            ground.PARA.tortuosity=[];
            
            ground.PARA.dt_max = [] ; %[sec]
            ground.PARA.dE_max = []; %[J/m3]
        end
        
        function ground = provide_STATVAR(ground)
            
            ground.STATVAR.upperPos = [];
            ground.STATVAR.lowerPos = [];
            ground.STATVAR.layerThick = []; % [m]
            
            ground.STATVAR.waterIce = []; % [m]
            ground.STATVAR.mineral = []; % [m]
            ground.STATVAR.organic = []; % [m]
            ground.STATVAR.energy = [];  % [J/m2]
            
            ground.STATVAR.T = [];  % [degree C]
            ground.STATVAR.water = [];  % [m]
            ground.STATVAR.ice = [];
            ground.STATVAR.air = [];  % [m]
            ground.STATVAR.thermCond = [];
            ground.STATVAR.deltaT =[];
            
            ground.STATVAR.saltConc =[]; %mol
            
            ground.STATVAR.area =[];
            
            ground.STATVAR.Lstar = [];
            ground.STATVAR.Qh = [];
            ground.STATVAR.Qe = [];
        end
        
        function ground = provide_CONST(ground)
            
            ground.CONST.L_f = [];
            
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
            
            ground.CONST.R = []; % [J/K mol]
            ground.CONST.Tmfw = [];
            
        end
        
        
        %----mandatory functions---------------
        %----initialization--------------------

        
        function ground = finalize_init(ground, forcing) %assign all variables, that must be calculated or assigned otherwise for initialization
            ground.PARA.heatFlux_lb = forcing.PARA.heatFlux_lb;
            ground.PARA.airT_height = forcing.PARA.airT_height;
            ground.STATVAR.area = ground.PARA.area + ground.STATVAR.T .* 0;
            
            ground = get_E_water_salt_FreezeDepress_Xice(ground);
            ground = conductivity(ground);
            ground = diffusivity_salt(ground);
            
            ground.STATVAR.Lstar = -100;
            ground.STATVAR.Qh = 0;
            ground.STATVAR.Qe = 0;
           
            ground.TEMP.d_energy = ground.STATVAR.energy.*0;
            ground.TEMP.d_salt = ground.STATVAR.energy.*0;
        end
        
        %---time integration------
        
        function ground = get_boundary_condition_u(ground, forcing) %functions specific for individual class, allow changing from Dirichlet to SEB
            
            ground = surface_energy_balance(ground, forcing);
            ground = get_boundary_condition_u_ZERO_SALT(ground);
        end
        
        function [ground, S_up] = penetrate_SW(ground, S_down)  %mandatory function when used with class that features SW penetration
            [ground, S_up] = penetrate_SW_no_transmission(ground, S_down);
        end
        
        function ground = get_boundary_condition_l(ground, forcing)
            ground.TEMP.F_lb = forcing.PARA.heatFlux_lb .* ground.STATVAR.area(end);
            ground.TEMP.d_energy(end) = ground.TEMP.d_energy(end) + ground.TEMP.F_lb;
            ground = get_boundary_condition_l_ZERO_SALT(ground);
        end
        
        function ground = get_derivatives_prognostic(ground)
            ground = get_derivative_energy(ground);
            ground = get_derivative_salt(ground);            
        end
        
        function timestep = get_timestep(ground)  %could involve check for several state variables
            timestep = get_timestep_heat_coduction(ground);
            %no check for salt, add if necesssary
        end
        
        function ground = advance_prognostic(ground, timestep)
            %energy
            ground.STATVAR.energy = ground.STATVAR.energy + timestep .* ground.TEMP.d_energy;
            ground.STATVAR.saltConc = ground.STATVAR.saltConc + timestep .* ground.TEMP.d_salt;
        end
        
        function ground = compute_diagnostic_first_cell(ground, forcing)
            ground = L_star(ground, forcing);
        end
        
        function ground = compute_diagnostic(ground, forcing)
            ground = get_T_water_salt_fcSimple_Xice(ground);
            ground = conductivity(ground);
            ground = diffusivity_salt(ground);
            
            ground.TEMP.d_energy = ground.STATVAR.energy.*0;
            ground.TEMP.d_salt = ground.STATVAR.energy.*0;
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
        
        function ground = check_trigger(ground, forcing)
            %do nothing
        end
        
        
                
        
        %-------------
        %lateral exchange
        function ground = lateral3D_pull_heat(ground, lateral)
            ground = lateral3D_pull_heat_simple(ground, lateral);
        end
        
        function ground = lateral3D_push_heat(ground, lateral)
            ground = lateral3D_push_heat_simple(ground, lateral);
        end
        
        
        %----inherited Tier 1 functions ------------
        
        function ground = get_derivative_energy(ground)
            ground = get_derivative_energy@HEAT_CONDUCTION(ground);
        end
        
        function ground = get_derivative_salt(ground)
            ground = get_derivative_salt@SALT(ground);
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
        
        function ground = get_E_water_salt_FreezeDepress_Xice(ground)
            ground = get_E_water_salt_FreezeDepress_Xice@SALT(ground);
        end
        
        function ground = diffusivity_salt(ground)
             ground = diffusivity_salt@SALT(ground);
        end
        
        function [ground, S_up] = penetrate_SW_no_transmission(ground, S_down)
            [ground, S_up] = penetrate_SW_no_transmission@SEB(ground, S_down);
        end
    end
    
end
