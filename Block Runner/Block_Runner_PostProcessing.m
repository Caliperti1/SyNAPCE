%  Data processing   
%  Caspian Bell
%  United States Military Academy
%  West Point, NY


function Block_Runner_PostProcessing(len, COPx, COPy, T,  penalty, n, config, vddist, subject, surface, datalocation)
% Define global variables for game
global Ypos
    

    % Excursions calculations
    TXml=sum(abs(diff(COPx)));
    
    TXap=sum(abs(diff(COPy)));
    
    % Acceleration and Velocity calculations
    ts=diff(T); 
   
    VELap=mean(diff(COPx)./ts);
    VELap=mean(diff(COPx)./ts);
    ACCml=mean(diff(diff(COPy)./ts));
    
    % Penalty calculations
    
    pen=mean(penalty);
    
    % TNSP calculations
    
    Modulus=sqrt(COPx.^2+COPy.^2); % Calculates modulus of the COP
    lineY=(len/(3*n)) * (1:n); % Creates array of all y positions of the lines of blocks
% Initialize variables and arrays
    strt=1; % Starting y position index
    MODest=[]; % Modulus estimator
    SD=1:n; % Standard deviation 
    TNSP=1:n; % Time to new stablity position

    for i = 1:n % Increments through each section between lines
        nd=find(Ypos>lineY(i),1)-1; % Finds last y index before next line
        SD(i)=std(Modulus(strt:nd)); % Calculates standard deviation of all the moduli in the section
        for j = strt:nd % Increments through each index in the section
            MODest(i,(1+j-strt))=mean(Modulus(strt:j)); % Caculates accumulating average 
        end    
        NSP=find(or(MODest(i,:)>MODest(i,(nd-strt+1))+.25*SD(i),MODest(i,:)<MODest(i,(nd-strt+1))-.25*SD(i)),1,"last"); % Finds last index of MODest that is outside of the final modulus by a quarter of the standard deviation
        TNSP(i)=T(NSP+strt+1)-T(strt); % Calculates differnce in time between start of section and NSP
%         subplot(n,1,i);
%         plot(MODest(i,:))
%         plot(MODest(i,:))
%         hold on
%         yline(MODest(i,(nd-strt+1))+.25*SD(i));
%         yline(MODest(i,(nd-strt+1))-.25*SD(i));
%         hold off
        strt=nd+1;
    end
%     plot(T,)
    TNSPavg=mean(TNSP); % Takes average of TNSP values
    SV=vddist/TNSPavg; % Calculates stabilization velocity (only for differing block configurations)
    met=readtable(datalocation); % Takes the metric table from excel
    dt=string(datetime);
    nmet={TXml TXap VELap ACCml pen TNSPavg str2double(subject) config dt surface};
    met=[met;nmet]; % Appends most recent trial onto the table
    writetable(met,datalocation); % Exports updated table to excel
 end