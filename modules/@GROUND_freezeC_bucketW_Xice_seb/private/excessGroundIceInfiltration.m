function ground = excessGroundIceInfiltration(ground)

meltwaterGroundIce=0;

T = ground.STATVAR.T;
water = ground.STATVAR.water;
K_delta=ground.STATVAR.layerThick;

if  sum(double(ground.STATVAR.T(1:end) > 0 & ground.STATVAR.excessGroundIce(1:end)==1))~=0
    disp('excessGroundIceInfiltration - excess ice thawing');
    %ground.STATVAR.excessGroundIce = ground.STATVAR.excessGroundIce==1 & ground.STATVAR.T <= 0;   %remove the thawed cell from the list
        
 
    %calculates amounts of soil constituents in [m]
    mineral = ground.STATVAR.mineral;
    organic = ground.STATVAR.organic; 
    natPor = ground.STATVAR.naturalPorosity .* ground.STATVAR.layerThick;
    actPor = ground.STATVAR.layerThick - mineral - organic;
    
    fieldCapacity = ground.STATVAR.field_capacity;

    % modification for infiltration
    
    %mobileWater = double(T>0) .* (water-natPor) .* double(water>natPor);
    
    %[startCell, ~]= LayerIndex(mobileWater~=0);
    startCell = find(double(ground.STATVAR.T(1:end) > 0 & ground.STATVAR.excessGroundIce(1:end)==1), 1, 'first');

    ground.STATVAR.excessGroundIce(startCell) = 0;   %remove the first thawed cell from the list
   
    
    %move solids down
    for i=startCell:-1:1
        F_solid_down=K_delta(i)-mineral(i)-organic(i)-natPor(i);
        j=i-1;
        while j>0 && F_solid_down>0
            mineralDown = min(mineral(j), mineral(j)./(mineral(j)+organic(j)).*F_solid_down);
            organicDown = min(organic(j), organic(j)./(mineral(j)+organic(j)).*F_solid_down);
            mineral(i)=mineral(i)+mineralDown;
            organic(i)=organic(i)+organicDown;
            mineral(j)=mineral(j)-mineralDown;
            organic(j)=organic(j)-organicDown;
            F_solid_down=F_solid_down-mineralDown-organicDown;
            j=j-1;
        end
    end
    
    %adjust the actual porosity
    actPor(1:startCell)=K_delta(1:startCell)-mineral(1:startCell)-organic(1:startCell);
    
    % move water up
    mobileWater=0;
    for i=startCell:-1:1
        totalWater=water(i)+mobileWater;
        mobileWater=totalWater-actPor(i);
        mobileWater=max(0,mobileWater);
        water(i)=totalWater-mobileWater;
    end
    
    %collect water from grid cells in domains without soil matrix
    mobileWater=0;
    for i=1:startCell
        if mineral(i)+organic(i)==0
            mobileWater=mobileWater+water(i);
            water(i)=0;
        end
    end
    
    % infiltrate from top to bottom
    i=1;
    while mobileWater>0 && i<=startCell
        if mineral(i)+organic(i)>0  %water is only added to cells with soil matrix
            maxWater=K_delta(i).*fieldCapacity(i);
            actualWater=water(i)+mobileWater;
            water(i)=min( actualWater, maxWater );
            mobileWater=max(0, actualWater-water(i));
        end
        i=i+1;
    end
    i=startCell;
    while mobileWater>0 && i>=1
        maxWater=actPor(i);
        actualWater=water(i)+mobileWater;
        water(i)=min(actualWater, maxWater);
        mobileWater=max(0, actualWater-water(i));
        i=i-1;
    end
    
    if mobileWater>1e-6
        error('xice - water infiltration - excess water after infiltration');
    end
    
    ground.STATVAR.water = water;
    
    ground.STATVAR.mineral = mineral;
    ground.STATVAR.organic = organic;
    ground.STATVAR.naturalPorosity = natPor./K_delta;
    ground.STATVAR.waterIce = double(ground.STATVAR.T>0) .* ground.STATVAR.water + double(ground.STATVAR.T<=0) .* ground.STATVAR.waterIce;
    
    ground.STATVAR.layerThick(1) = (mineral(1) + organic(1)) ./ (1-ground.STATVAR.naturalPorosity(1));  %change layer thickness of first cell
    
    if ground.STATVAR.layerThick(1) < 0.5 .* ground.STATVAR.layerThick(2)  %merge cells if first cell is too small
        disp('removing first cell')
        %extensive variables
        ground.STATVAR.layerThick(2) = ground.STATVAR.layerThick(1) + ground.STATVAR.layerThick(2);
        ground.STATVAR.layerThick(1) = [];
        ground.STATVAR.waterIce(2) = ground.STATVAR.waterIce(1) + ground.STATVAR.waterIce(2);
        ground.STATVAR.waterIce(1) = [];
        ground.STATVAR.water(2) = ground.STATVAR.water(1) + ground.STATVAR.water(2);
        ground.STATVAR.water(1) = []; %CHECK if routed away if there is more water than the cell is large enough
        ground.STATVAR.ice(2) = ground.STATVAR.ice(1) + ground.STATVAR.ice(2);
        ground.STATVAR.ice(1) = []; 
        ground.STATVAR.organic(2) = ground.STATVAR.organic(1) + ground.STATVAR.organic(2);
        ground.STATVAR.organic(1) = [];
        ground.STATVAR.mineral(2) = ground.STATVAR.mineral(1) + ground.STATVAR.mineral(2);
        ground.STATVAR.mineral(1) = [];
        
        %intensive variables
        ground.STATVAR.T(1) = [];
        ground.STATVAR.excessGroundIce(1) = [];
        ground.STATVAR.soil_type(1) = [];
        ground.STATVAR.naturalPorosity(1) = [];
        ground.STATVAR.field_capacity(1) = [];
        ground.STATVAR.heatCapacity(1) = [];
        ground.STATVAR.thermCond(1) = [];
        
        ground.STATVAR.air(1) = [];
        ground.STATVAR.air(1) = max(0, ground.STATVAR.layerThick(1) - ground.STATVAR.waterIce(1) - ground.STATVAR.organic(1) - ground.STATVAR.mineral(1));
        
        ground.LOOKUP.cT_frozen(1,:) =  [];
        ground.LOOKUP.cT_thawed(1,:) = [];
        ground.LOOKUP.conductivity(1,:) = [];
        ground.LOOKUP.capacity(1,:) = [];
        ground.LOOKUP.liquidWaterContent(1,:) = [];
                
    end
    


    
%     % remove air cells and mixed air/water cells above water table and adjust the GRID domains
%     while GRID.soil.cT_mineral(1)+GRID.soil.cT_organic(1)+wc(1)<=1e-6 || ...      % upper cell filled with pure air
%             (GRID.soil.cT_mineral(1)+GRID.soil.cT_organic(1)<=1e-6 && ( PARA.location.initial_altitude - GRID.general.K_grid(GRID.soil.cT_domain_ub+1) > PARA.location.absolute_maxWater_altitude) )
%         
%         disp('xice - update GRID - removing grid cell ...')
%         if wc(1)<=1e-6
%             disp('... upper cell wc=0')
%         elseif wc(1)==1
%             disp('... upper cell wc=1')
%         else
%             disp('... upper cell 0<wc<1')
%         end
%         
%         meltwaterGroundIce=meltwaterGroundIce+K_delta(1)*wc(1);
%         
%         % adjust air and soil domains and boundaries
%         GRID.air.cT_domain(GRID.soil.cT_domain_ub)=1;
%         GRID.air.K_domain(GRID.soil.K_domain_ub)=1;
%         GRID.air.cT_domain_lb=GRID.air.cT_domain_lb+1;
%         GRID.air.K_domain_lb=GRID.air.K_domain_lb+1;
%         GRID.soil.cT_domain(GRID.soil.cT_domain_ub)=0;
%         GRID.soil.K_domain(GRID.soil.K_domain_ub)=0;
%         GRID.soil.cT_domain_ub=GRID.soil.cT_domain_ub+1;
%         GRID.soil.K_domain_ub=GRID.soil.K_domain_ub+1;
%         GRID.soil.soilGrid(1)=[];
%         
%         %%% modification due to infiltration module
%         GRID.soil.cT_water(1)=[];
%         wc(1)=[];
%         %%%
%         
%         GRID.soil.cT_organic(1)=[];
%         GRID.soil.cT_natPor(1)=[];
%         GRID.soil.cT_actPor(1)=[];
%         GRID.soil.cT_mineral(1)=[];
%         GRID.soil.cT_soilType(1)=[];
%         
%         GRID.soil.excessGroundIce(1)=[];
%         
%     end
%     
%     % check if the uppermost soil cell contains water above water table
%     if GRID.soil.cT_mineral(1)+GRID.soil.cT_organic(1)<=1e-6 && ...
%             PARA.location.initial_altitude - GRID.general.K_grid(GRID.soil.cT_domain_ub) > PARA.location.absolute_maxWater_altitude
%         
%         disp('xice - checking upper cell for excess water');
%         
%         actualWater = wc(1)*K_delta(1);
%         h = PARA.location.absolute_maxWater_altitude - (PARA.location.initial_altitude-GRID.general.K_grid(GRID.soil.cT_domain_ub+1));
%         
%         if h<0
%             warning('xice - h<0. too much water above water table!')
%         end
%         
%         if actualWater>h
%             wc(1)=h./K_delta(1);
%             meltwaterGroundIce = meltwaterGroundIce + actualWater-h;
%         end
%         
%     end
    

    

    

    
end
