classdef WATER_FLUXES < BASE


    methods
        
        function ground = get_boundary_condition_u_water2(ground, forcing)
            rainfall = forcing.TEMP.rainfall ./ 1000 ./ 24 ./3600 .* ground.STATVAR.area(1);  %possibly add water from external source here 
            
            %partition already here in infiltration and surface runoff,
            %considering ET losses and potentially external fluxes
            saturation_first_cell = (ground.STATVAR.waterIce(1) - ground.STATVAR.field_capacity(1) .* ground.STATVAR.layerThick(1).* ground.STATVAR.area(1))./ (ground.STATVAR.layerThick(1).*ground.STATVAR.area(1) - ground.STATVAR.mineral(1) - ground.STATVAR.organic(1) - ground.STATVAR.field_capacity(1).*ground.STATVAR.layerThick(1).*ground.STATVAR.area(1));
            saturation_first_cell = max(0,min(1,saturation_first_cell)); % 0 water at field capacity, 1: water at saturation
            
            evap = double(ground.TEMP.d_water_ET(1)<0).*ground.TEMP.d_water_ET(1);
            condensation = double(ground.TEMP.d_water_ET(1)>0).*ground.TEMP.d_water_ET(1);
            
            rainfall = rainfall + condensation; %add condensation to rainfall to avoid overflowing of grid cell
            ground.TEMP.d_water_ET(1) = evap; %evaporation (water loss) subrtacted in get_derivative
            
            ground.TEMP.F_ub_water = double(rainfall <= -evap) .* rainfall + ...
                double(rainfall > -evap) .* (-evap + (rainfall + evap) .* reduction_factor_in(saturation_first_cell, ground));
            ground.TEMP.surface_runoff = rainfall - ground.TEMP.F_ub_water;
            
            ground.TEMP.T_rainWater =  max(0,forcing.TEMP.Tair);
            ground.TEMP.F_ub_water_energy = ground.TEMP.F_ub_water .* ground.CONST.c_w .* ground.TEMP.T_rainWater;
            
            ground.TEMP.d_water(1) = ground.TEMP.d_water(1) + ground.TEMP.F_ub_water;
            ground.TEMP.d_water_energy(1) = ground.TEMP.d_water_energy(1) + ground.TEMP.F_ub_water_energy;
        end
        
        
        function ground = get_boundary_condition_u_water_Xice(ground, forcing)  %simply add the water to first grid cell, excess taken up by Xwater, no checks needed
            rainfall = forcing.TEMP.rainfall ./ 1000 ./ 24 ./3600 .* ground.STATVAR.area(1);  %possibly add water from external source here 
            
            %partition already here in infiltration and surface runoff, considering ET losses and potentially external fluxes
            volume_matrix = ground.STATVAR.layerThick(1) .* ground.STATVAR.area(1) - ground.STATVAR.XwaterIce(1);
            saturation_first_cell = (ground.STATVAR.waterIce(1)  - ground.STATVAR.field_capacity(1) .* volume_matrix)./...
                (volume_matrix - ground.STATVAR.mineral(1) - ground.STATVAR.organic(1) - ground.STATVAR.field_capacity(1) .* volume_matrix);
            saturation_first_cell = max(0,min(1,saturation_first_cell)); % 0 water at field capacity, 1: water at saturation
            
            evap = double(ground.TEMP.d_water_ET(1)<0).*ground.TEMP.d_water_ET(1); %negative
            condensation = double(ground.TEMP.d_water_ET(1)>0).*ground.TEMP.d_water_ET(1);
            
            rainfall = rainfall + condensation; %add condensation to rainfall to avoid overflowing of grid cell
            ground.TEMP.d_water_ET(1) = evap; %evaporation (water loss) subrtacted in get_derivative
            
            ground.TEMP.F_ub_water = double(rainfall <= -evap) .* rainfall + ...
                double(rainfall > -evap) .* (-evap + (rainfall + evap) .* reduction_factor_in(saturation_first_cell, ground));
            ground.TEMP.F_ub_Xwater = rainfall - ground.TEMP.F_ub_water;
            
            ground.TEMP.T_rainWater =  max(0,forcing.TEMP.Tair);
            ground.TEMP.F_ub_water_energy = ground.TEMP.F_ub_water .* ground.CONST.c_w .* ground.TEMP.T_rainWater;
            ground.TEMP.F_ub_Xwater_energy = ground.TEMP.F_ub_Xwater .* ground.CONST.c_w .* ground.TEMP.T_rainWater;
            
            ground.TEMP.d_water(1) = ground.TEMP.d_water(1) + ground.TEMP.F_ub_water;
            ground.TEMP.d_water_energy(1) = ground.TEMP.d_water_energy(1) + ground.TEMP.F_ub_water_energy;
            ground.TEMP.d_Xwater(1) = ground.TEMP.d_Xwater(1) + ground.TEMP.F_ub_Xwater;
            ground.TEMP.d_Xwater_energy(1) = ground.TEMP.d_Xwater_energy(1) + ground.TEMP.F_ub_Xwater_energy;
        end
        
        
        function ground = get_boundary_condition_u_water_SNOW(ground, forcing)
            rainfall = forcing.TEMP.rainfall ./ 1000 ./ 24 ./3600 .* ground.STATVAR.area(1);  
            
            %partition already here in infiltration and surface runoff,
            %considering ET losses and potentially external fluxes
            remaining_pore_space = ground.STATVAR.layerThick(1).* ground.STATVAR.area(1) - ground.STATVAR.mineral(1) - ground.STATVAR.organic(1) - ground.STATVAR.ice(1);
            saturation_first_cell = (ground.STATVAR.waterIce(1) - ground.PARA.field_capacity .* remaining_pore_space) ./ ...
                (ground.STATVAR.layerThick(1).*ground.STATVAR.area(1) - remaining_pore_space); 
            saturation_first_cell = max(0,min(1,saturation_first_cell)); % 0 water at field capacity, 1: water at saturation
            
            ground.TEMP.F_ub_water = rainfall .* reduction_factor_in(saturation_first_cell, ground);
            ground.TEMP.surface_runoff = rainfall - ground.TEMP.F_ub_water;  %route this to surface pool
            
            ground.TEMP.T_rainWater =  max(0,forcing.TEMP.Tair);
            ground.TEMP.F_ub_water_energy = ground.TEMP.F_ub_water .* ground.CONST.c_w .* ground.TEMP.T_rainWater;
            
            ground.TEMP.d_water(1) = ground.TEMP.d_water(1) + ground.TEMP.F_ub_water;
            ground.TEMP.d_water_energy(1) = ground.TEMP.d_water_energy(1) + ground.TEMP.F_ub_water_energy;
        end
        
        
        function ground = get_boundary_condition_u_water_LAKE(ground, forcing)
            rainfall = forcing.TEMP.rainfall ./ 1000 ./ 24 ./3600 .* ground.STATVAR.area(1);  
            snowfall = forcing.TEMP.snowfall ./ 1000 ./ 24 ./3600 .* ground.STATVAR.area(1);
            ground.TEMP.F_ub_water = rainfall + snowfall;
            
            T_rainWater =  max(0,forcing.TEMP.Tair);
            T_snow = min(0,forcing.TEMP.Tair);
            ground.TEMP.F_ub_water_energy = rainfall .* ground.CONST.c_w .* T_rainWater + snowfall .* (ground.CONST.c_i .* T_snow - ground.CONST.L_f); 
            
            ground.TEMP.d_water(1) = ground.TEMP.d_water(1) + ground.TEMP.F_ub_water;
            ground.TEMP.d_water_energy(1) = ground.TEMP.d_water_energy(1) + ground.TEMP.F_ub_water_energy;
        end
        
        function ground = get_boundary_condition_u_water_LAKE_frozen(ground, forcing)
            rainfall = forcing.TEMP.rainfall ./ 1000 ./ 24 ./3600 .* ground.STATVAR.area(1);  
            ground.TEMP.F_ub_water = rainfall;
            
            T_rainWater =  max(0,forcing.TEMP.Tair);
            ground.TEMP.F_ub_water_energy = rainfall .* ground.CONST.c_w .* T_rainWater;
            
            ground.TEMP.d_water(1) = ground.TEMP.d_water(1) + ground.TEMP.F_ub_water;
            ground.TEMP.d_water_energy(1) = ground.TEMP.d_water_energy(1) + ground.TEMP.F_ub_water_energy;
        end
        
        function ground = get_boundary_condition_l_water2(ground)
            ground.TEMP.F_lb_water = 0;
            ground.TEMP.F_lb_water_energy = 0;
            
            ground.TEMP.d_water(end) = ground.TEMP.d_water(end) + ground.TEMP.F_lb_water;
            ground.TEMP.d_water_energy(end) = ground.TEMP.d_water_energy(end) + ground.TEMP.F_lb_water_energy;
        end
        
        function ground = get_derivative_water2(ground) %adapts the fluxes automatically so that no checks are necessary when advancing the prognostic variable 
            saturation = (ground.STATVAR.waterIce - ground.STATVAR.field_capacity .* ground.STATVAR.layerThick.*ground.STATVAR.area)./ (ground.STATVAR.layerThick.*ground.STATVAR.area - ground.STATVAR.mineral - ground.STATVAR.organic - ground.STATVAR.field_capacity.*ground.STATVAR.layerThick.*ground.STATVAR.area);
            saturation = max(0,min(1,saturation)); % 0 water at field capacity, 1: water at saturation
            
            guaranteed_flow = ground.TEMP.d_water_ET;  %add other external fluxes here
            guaranteed_flow_energy = ground.TEMP.d_water_ET_energy;
            
            %outflow
            d_water_out = max(0, ground.PARA.hydraulicConductivity .* ground.STATVAR.water ./ ground.STATVAR.layerThick); % area cancels out; make this depended on both involved cells? 
            guaranteed_inflow = guaranteed_flow.* double(guaranteed_flow > 0); 
            d_water_out = double(guaranteed_inflow >= d_water_out) .* d_water_out + double(guaranteed_inflow < d_water_out) .* ...
                 (guaranteed_inflow + (d_water_out - guaranteed_inflow) .* reduction_factor_out(saturation, ground)); %this is positive when flowing out
            d_water_out(end,1) = 0; % lower boundary handled elsewhere
             %d_water_out(end,1) = -ground.TEMP.F_lb_water; %positive
             
            %inflow
            d_water_in = d_water_out .*0;
            d_water_in(2:end) = d_water_out(1:end-1);
            guaranteed_outflow = guaranteed_flow.* double(guaranteed_flow < 0);
            d_water_in = double(-guaranteed_outflow >= d_water_in) .* d_water_in + double(-guaranteed_outflow < d_water_in) .* ...
                (-guaranteed_outflow + (d_water_in + guaranteed_outflow).* reduction_factor_in(saturation, ground));
            %d_water_in(1) = ground.TEMP.F_ub_water; %already checked in UB, that space is available
            
            %avoid rounding errors
            %saturated = ground.STATVAR.layerThick.*ground.STATVAR.area <= ground.STATVAR.waterIce + ground.STATVAR.mineral + ground.STATVAR.organic;
            %d_water_in(saturated) = min(d_water_in(saturated), -guaranteed_outflow(saturated));
            
            %readjust outflow
            d_water_out(1:end-1) = d_water_in(2:end); %reduce outflow if inflow is impossible
            
            %energy advection
            d_water_out_energy = d_water_out .* (double(ground.STATVAR.T>=0) .* ground.CONST.c_w + double(ground.STATVAR.T<0) .* ground.CONST.c_i) .* ground.STATVAR.T;
            d_water_in_energy = d_water_out.*0;
            d_water_in_energy(2:end,1) = d_water_out_energy(1:end-1,1); 
            %d_water_in_energy(1) = ground.TEMP.F_ub_water_energy;
            %d_water_out_energy(end) = -ground.TEMP.F_lb_water_energy;
            
            %sum up               
            ground.TEMP.d_water = ground.TEMP.d_water + guaranteed_flow - d_water_out + d_water_in; 
            ground.TEMP.d_water_energy = ground.TEMP.d_water_energy + guaranteed_flow_energy - d_water_out_energy + d_water_in_energy;
            
            ground.TEMP.d_water_in = d_water_in; % at this stage nice-to-have variables, good for troubleshooting
            ground.TEMP.d_water_out = d_water_out;
        end
        
        
        function ground = get_derivative_water_Xice(ground) %adapts the fluxes automatically so that no checks are necessary when advancing the prognostic variable
            volume_matrix = ground.STATVAR.layerThick .* ground.STATVAR.area - ground.STATVAR.XwaterIce;
            saturation = (ground.STATVAR.waterIce  - ground.STATVAR.field_capacity .* volume_matrix)./...
                (volume_matrix - ground.STATVAR.mineral - ground.STATVAR.organic - ground.STATVAR.field_capacity .* volume_matrix);
            saturation = max(0,min(1,saturation)); % 0 water at field capacity, 1: water at saturation
            
            guaranteed_flow = ground.TEMP.d_water_ET;  %add other external fluxes here
            guaranteed_flow_energy = ground.TEMP.d_water_ET_energy;
            
            %outflow
            d_water_out = ground.PARA.hydraulicConductivity .* ground.STATVAR.water ./ (ground.STATVAR.layerThick - ground.STATVAR.XwaterIce ./ground.STATVAR.area); % area cancels out; make this depended on both involved cells? 
            guaranteed_inflow = guaranteed_flow.* double(guaranteed_flow > 0); 
            d_water_out = double(guaranteed_inflow >= d_water_out) .* d_water_out + double(guaranteed_inflow < d_water_out) .* ...
                 (guaranteed_inflow + (d_water_out - guaranteed_inflow) .* reduction_factor_out(saturation, ground)); %this is positive when flowing out
            d_water_out(end,1) = 0; % lower boundary handled elsewhere
             %d_water_out(end,1) = -ground.TEMP.F_lb_water; %positive
            
            %inflow
            d_water_in = d_water_out .*0;
            d_water_in(2:end) = d_water_out(1:end-1);
            guaranteed_outflow = guaranteed_flow.* double(guaranteed_flow < 0);
            d_water_in = double(-guaranteed_outflow >= d_water_in) .* d_water_in + double(-guaranteed_outflow < d_water_in) .* ...
                (-guaranteed_outflow + (d_water_in + guaranteed_outflow).* reduction_factor_in(saturation, ground));
            %d_water_in(1) = ground.TEMP.F_ub_water; %already checked in UB, that space is available
            
            %readjust outflow
            d_water_out(1:end-1) = d_water_in(2:end); %reduce outflow if inflow is impossible
            
            %energy advection
            d_water_out_energy = d_water_out .* (double(ground.STATVAR.T>=0) .* ground.CONST.c_w + double(ground.STATVAR.T<0) .* ground.CONST.c_i) .* ground.STATVAR.T;
            d_water_in_energy = d_water_out.*0;
            d_water_in_energy(2:end,1) = d_water_out_energy(1:end-1,1); 
            %d_water_in_energy(1) = ground.TEMP.F_ub_water_energy;
            %d_water_out_energy(end) = -ground.TEMP.F_lb_water_energy;
            
            %sum up               
            ground.TEMP.d_water = ground.TEMP.d_water + guaranteed_flow - d_water_out + d_water_in; 
            ground.TEMP.d_water_energy = ground.TEMP.d_water_energy + guaranteed_flow_energy - d_water_out_energy + d_water_in_energy;
            
            ground.TEMP.d_water_in = d_water_in; % at this stage nice-to-have variables, good for troubleshooting, later necessary to route solutes
            ground.TEMP.d_water_out = d_water_out;
        end
        
        
        function ground = get_derivative_Xwater(ground)  %routes Xwater up when Xice has melted
            %saturation = ground.STATVAR.Xwater ./ ground.STATVAR.area ./ (ground.PARA.hydraulicConductivity .* ground.PARA.dt_max);
            %saturation = max(0,min(1,saturation)); % 0 no Xwater, 1: water routed up within maximum timestep
            d_Xwater_out = ground.PARA.hydraulicConductivity .* ground.STATVAR.area; %  .* reduction_factor_out(saturation, ground); 
            d_Xwater_out(1,1) = 0; %Xwater stays in uppermost cell, must be removed elesewhere
            
            d_Xwater_out(d_Xwater_out > 0) = min(d_Xwater_out(d_Xwater_out > 0), ground.STATVAR.Xwater(d_Xwater_out > 0) ./ ground.PARA.dt_max); %makes explicit timestep check unnecessary

            d_Xwater_in = d_Xwater_out .*0;
            d_Xwater_in(1:end-1) = d_Xwater_out(2:end) .* double(ground.STATVAR.T(1:end-1)>0); % water can only be taken up by unfrozen cells, important for lateral Xice melt (e.g. palsa case)
            
            d_Xwater_out(2:end) = d_Xwater_in(1:end-1); %reduce outflow if inflow is impossible
            
            d_Xwater_out_energy = d_Xwater_out .* ground.CONST.c_w .* ground.STATVAR.T;
            d_Xwater_in_energy = d_Xwater_out .*0;
            d_Xwater_in_energy(1:end-1) = d_Xwater_out_energy(2:end);
            
            ground.TEMP.d_Xwater = ground.TEMP.d_Xwater - d_Xwater_out + d_Xwater_in; 
            %ground.TEMP.d_Xwater(1) = ground.TEMP.d_Xwater(1) + ground.TEMP.F_ub_Xwater;
            ground.TEMP.d_Xwater_energy = ground.TEMP.d_Xwater_energy - d_Xwater_out_energy + d_Xwater_in_energy;
            %ground.TEMP.d_Xwater_energy(1) = ground.TEMP.d_Xwater_energy(1) + ground.TEMP.F_ub_Xwater_energy;
        end
        
        
        function ground = get_derivative_water_SNOW(ground) %adapts the fluxes automatically so that no checks are necessary when advancing the prognostic variable
            remaining_pore_space = ground.STATVAR.layerThick.* ground.STATVAR.area - ground.STATVAR.mineral - ground.STATVAR.organic - ground.STATVAR.ice;
            %saturation = (ground.STATVAR.waterIce - ground.PARA.field_capacity .* remaining_pore_space) ./ ...
            %    (ground.STATVAR.layerThick.*ground.STATVAR.area - remaining_pore_space); 
            saturation = (ground.STATVAR.water - ground.PARA.field_capacity .* remaining_pore_space) ./ ...
                (remaining_pore_space - ground.PARA.field_capacity .* remaining_pore_space); 
            
            saturation = max(0,min(1,saturation)); % 0 water at field capacity, 1: water at saturation
              
            %outflow
            d_water_out = ground.PARA.hydraulicConductivity .* ground.STATVAR.water ./ ground.STATVAR.layerThick; % area cancels out; make this depended on both involved cells?
            d_water_out = d_water_out .* reduction_factor_out(saturation, ground); %this is positive when flowing out
            d_water_out(end,1) = 0; % lower boundary handled elsewhere
            %d_water_out(end,1) = -ground.TEMP.F_lb_water; %positive
            
            %inflow
            d_water_in = d_water_out .*0;
            d_water_in(2:end) = d_water_out(1:end-1);
            d_water_in = d_water_in .* reduction_factor_in(saturation, ground);
            %d_water_in(1) = ground.TEMP.F_ub_water; %already checked in UB, that space is available
            
            %readjust outflow
            d_water_out(1:end-1) = d_water_in(2:end); %reduce outflow if inflow is impossible
            
            %energy advection
            d_water_out_energy = d_water_out .* ground.CONST.c_w .* ground.STATVAR.T;
            d_water_in_energy = d_water_out.*0;
            d_water_in_energy(2:end,1) = d_water_out_energy(1:end-1,1);
            %d_water_in_energy(1) = ground.TEMP.F_ub_water_energy;
            %d_water_out_energy(end) = -ground.TEMP.F_lb_water_energy;
            
            %sum up
            ground.TEMP.d_water = ground.TEMP.d_water - d_water_out + d_water_in;
            ground.TEMP.d_water_energy = ground.TEMP.d_water_energy - d_water_out_energy + d_water_in_energy;
            
            ground.TEMP.d_water_in = d_water_in; % at this stage nice-to-have variables, good for troubleshooting
            ground.TEMP.d_water_out = d_water_out;
        end
        
        
        function rf = reduction_factor_out(saturation, ground)  %part of get_derivative_water2(ground)
            smoothness = 3e-2;
            rf = (1-exp(-saturation./smoothness));
        end
        
        function rf = reduction_factor_in(saturation, ground)   %part of get_derivative_water2(ground)
            smoothness = 3e-2;
            rf = (1- exp((saturation-1)./smoothness));
        end
        
        function timestep = get_timestep_water(ground)
            %outflow + inflow
%             timestep = ( double(ground.TEMP.d_water <0 & ground.STATVAR.waterIce > ground.STATVAR.field_capacity .* ground.STATVAR.layerThick .* ground.STATVAR.area) .* (ground.STATVAR.waterIce - ground.STATVAR.field_capacity .* ground.STATVAR.layerThick .* ground.STATVAR.area) ./ -ground.TEMP.d_water + ...
%                  double(ground.TEMP.d_water > 0) .* (ground.STATVAR.layerThick .* ground.STATVAR.area - ground.STATVAR.mineral - ground.STATVAR.organic - ground.STATVAR.waterIce ) ./ ground.TEMP.d_water); %[m3 / (m3/sec) = sec]
             timestep = ( double(ground.TEMP.d_water <0 & ground.STATVAR.waterIce > ground.STATVAR.field_capacity .* ground.STATVAR.layerThick .* ground.STATVAR.area) .* (ground.STATVAR.waterIce - ground.STATVAR.field_capacity .* ground.STATVAR.layerThick .* ground.STATVAR.area) ./ -ground.TEMP.d_water + ...
                 double(ground.TEMP.d_water > 0) .* (ground.STATVAR.layerThick .* ground.STATVAR.area - ground.STATVAR.mineral - ground.STATVAR.organic - ground.STATVAR.waterIce ) ./ ground.TEMP.d_water); %[m3 / (m3/sec) = sec]
             timestep(timestep<=0) = ground.PARA.dt_max;
             timestep=nanmin(timestep);
           
             
%              timestep2= nanmin(0.01.*(ground.STATVAR.layerThick .* ground.STATVAR.area - ground.STATVAR.mineral - ground.STATVAR.organic)./abs(ground.TEMP.d_water));
%              timestep = min(timestep, timestep2);
        end
        
        function timestep = get_timestep_Xwater(ground)
            %only outflow
            timestep = double(ground.TEMP.d_water <0) .* ground.STATVAR.Xwater ./ -ground.TEMP.d_water;
             
             timestep(timestep<=0) = ground.PARA.dt_max;
             timestep=nanmin(timestep);

             %if negative, set to max_timestep
        end
        
        function timestep = get_timestep_water_SNOW(ground)
            %outflow + inflow
            remaining_pore_space = ground.STATVAR.layerThick.* ground.STATVAR.area - ground.STATVAR.mineral - ground.STATVAR.organic - ground.STATVAR.ice;
            
            %timestep = ( double(ground.TEMP.d_water <0) .* (ground.STATVAR.waterIce - ground.PARA.field_capacity .* remaining_pore_space) ./ -ground.TEMP.d_water + ...
            %     double(ground.TEMP.d_water > 0) .* (ground.STATVAR.layerThick .* ground.STATVAR.area - ground.STATVAR.mineral - ground.STATVAR.organic - ground.STATVAR.waterIce ) ./ ground.TEMP.d_water); %[m3 / (m3/sec) = sec]
            timestep = ( double(ground.TEMP.d_water <0 & ground.STATVAR.water > ground.PARA.field_capacity .* remaining_pore_space ) .* (ground.STATVAR.water - ground.PARA.field_capacity .* remaining_pore_space) ./ -ground.TEMP.d_water + ...
                double(ground.TEMP.d_water > 0) .* (ground.STATVAR.layerThick .* ground.STATVAR.area - ground.STATVAR.mineral - ground.STATVAR.organic - ground.STATVAR.waterIce ) ./ ground.TEMP.d_water); %[m3 / (m3/sec) = sec]
            
            timestep(timestep<=0) = ground.PARA.dt_max;
            timestep=nanmin(timestep);
            
        end
        
        

        
    end
end

