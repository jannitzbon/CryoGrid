classdef IA_SNOW_GROUND_VEGETATION
    
    properties
        IA_PARENT_GROUND
        IA_CHILD_SNOW
        STATUS
    end
    
    methods
        
        function ia_snow_ground_vegetation = get_boundary_condition_u(ia_snow_ground_vegetation, forcing)
            if ia_snow_ground_vegetation.STATUS == 1 || forcing.TEMP.snowfall > 0 %non-zero SWE, but snow is still a child, or snowfall occurring
                
                ia_snow_ground_vegetation.IA_PARENT_GROUND.STATVAR.vegetation.flux.albsoib = [0.8,0.8]; % Direct beam albedo of ground (soil)
                ia_snow_ground_vegetation.IA_PARENT_GROUND.STATVAR.vegetation.flux.albsoid = [0.8,0.8]; % Diffuse albedo of ground (soil)
                                
                ia_snow_ground_vegetation.IA_CHILD_SNOW = get_boundary_condition_u(ia_snow_ground_vegetation.IA_CHILD_SNOW, forcing);
                ia_snow_ground_vegetation.IA_PARENT_GROUND = surface_energy_forest(ia_snow_ground_vegetation.IA_PARENT_GROUND, forcing);
                
                ia_snow_ground_vegetation.STATUS = 1;
 
            else
                
                ia_snow_ground_vegetation.IA_PARENT_GROUND.STATVAR.vegetation.flux.albsoib = [0.2,0.2]; % Direct beam albedo of ground (soil)
                ia_snow_ground_vegetation.IA_PARENT_GROUND.STATVAR.vegetation.flux.albsoid = [0.2,0.2]; % Diffuse albedo of ground (soil)
                
                ia_snow_ground_vegetation.IA_PARENT_GROUND = surface_energy_forest(ia_snow_ground_vegetation.IA_PARENT_GROUND, forcing);
            end
        end
        
        function ia_snow_ground_vegetation = get_derivative_energy(ia_snow_ground_vegetation)
%                         if ia_snow_ground_vegetation.STATUS == 1 %non-zero SWE, but snow is still a child
%                             snow = ia_snow_ground_vegetation.IA_CHILD_SNOW;
%                             ground = ia_snow_ground_vegetation.IA_PARENT_GROUND;
%                             fraction_snow = snow.STATVAR.waterIce./(snow.PARA.swe_per_cell./2);
%                             fraction_snow = min(1, fraction_snow);
%             %
            %                 %change parent variable
            %                 ground.TEMP.F_ub = (1-fraction_snow) .* ground.TEMP.F_ub + fraction_snow.* snow.TEMP.F_ub; %mix the surface heat fluxes from snow and ground
            %
            %                 ground.STATVAR.Lout = (1-fraction_snow) .* ia_snow_ground.IA_PARENT_GROUND.STATVAR.Lout + fraction_snow.* snow.STATVAR.Lout; %mix the surface heat fluxes from snow and ground
            %                 ground.STATVAR.Sout = (1-fraction_snow) .* ia_snow_ground.IA_PARENT_GROUND.STATVAR.Sout + fraction_snow.* snow.STATVAR.Sout; %mix the surface heat fluxes from snow and ground
            %                 ground.STATVAR.Qh = (1-fraction_snow) .* ground.STATVAR.Qh + fraction_snow.* snow.STATVAR.Qh; %mix the surface heat fluxes from snow and ground
            %                 ground.STATVAR.Qe = (1-fraction_snow) .* ground.STATVAR.Qe + fraction_snow.* snow.STATVAR.Qe; %mix the surface heat fluxes from snow and ground
            %                 %mixing of Qh and Qe will impact atmospheric stability
            %
            %                 layerThick = ground.STATVAR.layerThick;
            %                 layerThick(1,1) = layerThick(1,1) + snow.STATVAR.layerThick; %add thickness of snow cell for calculation of effective conductivities
            %                 fluxes = (ground.STATVAR.T(1:end-1) - ground.STATVAR.T(2:end)) .* ground.STATVAR.thermCond(1:end-1) .* ground.STATVAR.thermCond(2:end) ./...
            %                     (ground.STATVAR.thermCond(1:end-1).* layerThick(2:end)./2 +  ground.STATVAR.thermCond(2:end).* layerThick(1:end-1)./2 );
            %
            %                 d_energy=ground.STATVAR.energy.*0;
            %                 d_energy(1) = ground.TEMP.F_ub - fluxes(1);
            %                 d_energy(2:end-1) = fluxes(1:end-1) - fluxes(2:end);
            %                 d_energy(end) = ground.TEMP.F_lb + fluxes(end);
            %
            %                 ground.TEMP.d_energy = d_energy;
            %
            %                 ia_snow_ground_vegetation.IA_PARENT_GROUND = ground;
            %             else
            %                 ia_snow_ground_vegetation.IA_PARENT_GROUND = get_derivative_energy(ia_snow_ground_vegetation.IA_PARENT_GROUND); %call normal function
            %             end
        end
        
        function ia_snow_ground_vegetation = advance_prognostic(ia_snow_ground_vegetation, timestep)
            if ia_snow_ground_vegetation.STATUS == 1 %non-zero SWE, but snow is still a child
                snow = ia_snow_ground_vegetation.IA_CHILD_SNOW;
                
                snow.STATVAR.energy = snow.STATVAR.energy + timestep .* snow.TEMP.snow_energy + timestep .* snow.TEMP.rain_energy; %only the energy from new snow
                snow.STATVAR.waterIce = snow.STATVAR.waterIce + timestep .* (snow.TEMP.snowfall + snow.TEMP.rainfall);
                snow.STATVAR.ice_fraction = (snow.STATVAR.ice + timestep .* snow.TEMP.snowfall)./ (snow.STATVAR.layerThick + timestep .* snow.TEMP.snowfall ./ (snow.PARA.density ./snow.CONST.rho_w));
                snow.STATVAR.target_density = snow.STATVAR.ice_fraction; %remove later
%                 snow.STATVAR.layerThick = snow.STATVAR.layerThick + timestep .* snow.TEMP.snowfall ./ (snow.PARA.density ./snow.CONST.rho_w);
            end
        end
        
        function ia_snow_ground_vegetation = compute_diagnostic(ia_snow_ground_vegetation)
            if ia_snow_ground_vegetation.STATUS == 1 %non-zero SWE, but snow is still a child
                snow = ia_snow_ground_vegetation.IA_CHILD_SNOW;
                ground = ia_snow_ground_vegetation.IA_PARENT_GROUND;
                
                %do something
                
                L_f = ground.CONST.L_f;
                c_w = ground.CONST.c_w;
                c_i = ground.CONST.c_i;
                c_o = ground.CONST.c_o;
                c_m = ground.CONST.c_m;

                E_frozen = -L_f.*(ground.STATVAR.waterIce(1) + snow.STATVAR.waterIce);
                waterIce = ground.STATVAR.waterIce(1) + snow.STATVAR.waterIce;
                energy = ground.STATVAR.energy(1) + snow.STATVAR.energy; %total energy of combined cell
                
                T = double(energy < E_frozen) .* (energy - E_frozen) ./ (c_i.*waterIce + c_m.*ground.STATVAR.mineral(1,1) + c_o.*ground.STATVAR.organic(1,1)) + ...
                        double(energy >0) .* energy ./ (c_i.*waterIce + c_m.*ground.STATVAR.mineral(1,1) + c_o.*ground.STATVAR.organic(1,1));
                ice = double(energy <= E_frozen) .*waterIce + double(energy > E_frozen & energy < 0) .* energy ./ (-L_f);
                water = double(energy >= 0) .*waterIce + double(energy > - L_f.*waterIce & energy < 0) .* (energy + L_f.*waterIce) ./ L_f;
                fraction_snow = snow.STATVAR.waterIce ./ (ground.STATVAR.waterIce(1) + snow.STATVAR.waterIce);
                ground.STATVAR.water(1,1) = (1-fraction_snow) .*  water;
                snow.STATVAR.water = fraction_snow .*  water;
                ground.STATVAR.ice(1,1) = (1-fraction_snow) .*  ice;
                snow.STATVAR.ice = fraction_snow .*  ice;
                ground.STATVAR.T(1,1) = T;
                snow.STATVAR.T = T;
                
                snow.STATVAR.layerThick = snow.STATVAR.ice ./snow.STATVAR.ice_fraction; %conserving old density 
                runoff = max(0, snow.STATVAR.water - snow.PARA.field_capacity .* (1-snow.STATVAR.ice_fraction) .* snow.STATVAR.layerThick);  %could be used to reroute in the ground
                snow.STATVAR.water = min(snow.STATVAR.water, snow.PARA.field_capacity .* (1-snow.STATVAR.ice_fraction) .* snow.STATVAR.layerThick);
                snow.STATVAR.waterIce = snow.STATVAR.water + snow.STATVAR.ice;
                
                snow.STATVAR.energy = snow.STATVAR.ice .* (c_i.*T - L_f); %redistribute energy between snow and ground cell
                ground.STATVAR.energy(1) = energy - snow.STATVAR.energy;
            end
            
            if ia_snow_ground_vegetation.IA_CHILD_SNOW.STATVAR.waterIce == 0
                ia_snow_ground_vegetation.STATUS = 0;
                ia_snow_ground_vegetation.IA_CHILD_SNOW = initialize_zero_snow(ia_snow_ground_vegetation.IA_CHILD_SNOW, ia_snow_ground_vegetation.IA_PARENT_GROUND); %set all variables to zero
            end
        end
        %         end
        %
        %         function ia_snow_ground = mix_conductivity(ia_snow_ground)
        %             if ia_snow_ground.STATUS == 1 %non-zero SWE, but snow is still a child
        %                 snow = ia_snow_ground.IA_CHILD_SNOW;
        %                 ground = ia_snow_ground.IA_PARENT_GROUND;
        %
        %                 snow = conductivity(snow);
        %                 mixed_cond = (snow.STATVAR.layerThick + ground.STATVAR.layerThick(1,1)) .* snow.STATVAR.thermCond .* ground.STATVAR.thermCond(1,1) ./ ...
        %                     (snow.STATVAR.layerThick .* ground.STATVAR.thermCond(1,1) + ground.STATVAR.layerThick(1,1) .* snow.STATVAR.thermCond);
        %                 ground.STATVAR.thermCond(1,1) = mixed_cond;
        %             end
        %         end
        
        function ia_snow_ground_vegetation = check_trigger(ia_snow_ground_vegetation)
            if ia_snow_ground_vegetation.STATUS == 1 && ia_snow_ground_vegetation.IA_CHILD_SNOW.STATVAR.waterIce > ia_snow_ground_vegetation.IA_CHILD_SNOW.PARA.swe_per_cell./2
                
                ia_snow_ground_vegetation.IA_CHILD_SNOW.NEXT = ia_snow_ground_vegetation.IA_PARENT_GROUND.NEXT; %IA_VEGETATION_GROUND is next of Snow.
                ia_snow_ground_vegetation.IA_CHILD_SNOW.NEXT.PREVIOUS = ia_snow_ground_vegetation.IA_CHILD_SNOW; %ok
                
                ia_snow_ground_vegetation.IA_CHILD_SNOW.PREVIOUS = ia_snow_ground_vegetation.IA_PARENT_GROUND;
                ia_snow_ground_vegetation.IA_PARENT_GROUND.NEXT = ia_snow_ground_vegetation.IA_CHILD_SNOW;
                
                temp_store = ia_snow_ground_vegetation.IA_CHILD_SNOW; %the snow class = temp_store
                
                %put snow on bottom
                ia_class = get_IA_class(class(temp_store), class(temp_store.PREVIOUS)); % get IA class between Snow and Snow. previous = Vegetation
                temp_store.IA_PREVIOUS = ia_class; % Before Snow is IA Vegetation Snow
                temp_store.IA_PREVIOUS.NEXT = temp_store; % Next of IA Vegetation Snow is Snow
                temp_store.IA_PREVIOUS.PREVIOUS = temp_store.PREVIOUS; % temp_store.PREVIOUS = Vegetation
                temp_store.PREVIOUS.IA_NEXT = temp_store.IA_PREVIOUS; % temp_store.IA_PREVIOUS = IA Vegetation Snow
                
                
                ia_snow_ground_vegetation = [];  % destroy the class
            end
        end
        
    end
    
end


















