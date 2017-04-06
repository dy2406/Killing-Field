function [pos_r,pos_phi,pos_t] = ...
    BH(BH_Type,BH_L,BH_M,P_R,P_E,P_L,POSITION_ARRAY_SIZE,d_tau)

%POSITION_ARRAY_SIZE = 30000;
%d_tau = 0.01;
%P_R = 20; %Particle Initial radius
%P_E = -0.01; %Particle Initial Energy
%P_L = 12.0; %Particle angular momentum
%BH_Type = 0; % 0-Newton/1-Scwarz/2-Kerr
%BH_L = 0; %Black Hole Angular Momentum
%BH_M = 1; %Black Hole Mass

%%NOTE THAT GEOMETRIZED UNITS ARE USED THROUGHOUT (G=1,c=1)
%%TODO: Add support for massless particles.

%pos_x = zeros(1,POSITION_ARRAY_SIZE);
%pos_y = zeros(1,POSITION_ARRAY_SIZE);
pos_phi = linspace(0,2*pi*3,POSITION_ARRAY_SIZE);
pos_r = zeros(1,POSITION_ARRAY_SIZE);
pos_r(1) = P_R;
pos_t = zeros(1,POSITION_ARRAY_SIZE);

%Whether particle starts infalling or outgoing
%We are going to leave as 1, as it is more interesting
ingoing_flag = 1;

if BH_Type == 1
    %%TODO: Account for falling into BH, Currently get imaginary values and
    %%Generally screwy behavior. Whoopsie
    
    %Check for valid energy/Angular momentum values
    if (P_E^2 - (1-2*BH_M/pos_r(1))*(1+P_L^2/pos_r(1)^2)) < 0
        fprintf('Invalid Energy/Angular Momentum Selection');
        pos_t = [];
        return;
    end
    
    %Find Turning points based on tailored potential
    potentialPolynom = [(P_E^2-1) 2*BH_M -P_L^2 2*BH_M*P_L^2];
    turningRoots = roots(potentialPolynom);
    turningPoints = zeros(1,3);
    for i = 1:length(turningRoots)
        if turningRoots(i) > 0 && imag(turningRoots(i)) == 0
            turningPoints(i) = turningRoots(i);
        end
    end
    turningPoints(turningPoints==0) = []; %Deletes zero value
    
    %Do actual proper time evolution
    for i=2:POSITION_ARRAY_SIZE
        pos_t(i) = pos_t(i-1) + d_tau*(P_E/(1-2*BH_M/pos_r(i-1)));
        pos_phi(i) = pos_phi(i-1) + d_tau*(P_L/(pos_r(i-1)^2));
        %Check if particle is ingoing or outgoing and advance properly
        if ingoing_flag == 1
            pos_r(i) = pos_r(i-1) - d_tau*...
                (sqrt(P_E^2-(1-2*BH_M/pos_r(i-1))*(1+P_L^2/pos_r(i-1)^2)));
        else
            pos_r(i) = pos_r(i-1) + d_tau*...
                (sqrt(P_E^2-(1-2*BH_M/pos_r(i-1))*(1+P_L^2/pos_r(i-1)^2)));
        end
        
        %Check if particle crosses turning point & if so maintain current
        %radius and switch ingoing/outgoing flag
        for elm = turningPoints
            if (pos_r(i) - elm)*(pos_r(i-1) - elm) < 0
                pos_r(i) = pos_r(i-1);
                if ingoing_flag == 1
                    ingoing_flag = 0;
                    break
                else
                    ingoing_flag = 1;
                    break
                end
            end
        end
    end %End proper time progression loop

    %End of Schwarzchild treatment
elseif BH_Type == 0
    
    %Calculate initial coordinate velocities
    phi_dot = P_L/P_R^2;
    r_dot = sqrt(2*P_E-P_L^2/P_R^2+2*BH_M/P_R);
    if imag(r_dot) ~= 0
        fprintf('Invalid Energy/Angular Momentum Selection');
        pos_t = [];
        return;
    end
    
    %Circular orbit, muy bueno
    if r_dot == 0
        for i=2:POSITION_ARRAY_SIZE
            pos_t(i) = pos_t(i-1)+d_tau;
            pos_phi(i) = pos_phi(i-1) + d_tau*(P_L/P_R^2);
            pos_r(i) = P_R;
        end
        return
    end
        
    
    %Solve for eccentricity and true anomaly in accordance with Wikipedia
    %Article on Kepler Orbits, wrt Determintation from Initial conditions
    p = (P_R*phi_dot)^2/BH_M;
    F = @(y) [y(1)*cos(y(2))+1-phi_dot/sqrt(BH_M/p) ...
        y(1)*sin(y(2))-r_dot/sqrt(BH_M/p)];
    
    eAndTheta = fsolve(F,[1 pi]);
    
    %%This currently only works nicely for closed orbits so
    %%fix later & account for coordinate time progression
    pos_phi = linspace(0,sign(P_L)*2*pi,POSITION_ARRAY_SIZE);
    
    
    for i=2:POSITION_ARRAY_SIZE
        pos_t(i) = pos_t(i-1)+d_tau;
        pos_phi(i) = pos_phi(i-1) + d_tau*(P_L/pos_r(i-1)^2);
        pos_r(i) = p./(1+eAndTheta(1).*cos(pos_phi(i)-eAndTheta(2)));
    end
elseif BH_Type == 2
    %Stuff
end

%fplot(@(z) -(1-2*BH_M/z)*(1+P_L^2/z^2))

%polarplot(pos_phi,pos_r); %Display final data
