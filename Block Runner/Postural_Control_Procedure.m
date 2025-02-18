clear all
close all
clc

% Define global variables for game
global r_wbs vfwd N arena_w harena f angle_wbs w corners_b stance pen lossfactor hBlocks2D sensitivity acc dist path condition sortv len wid mN rN lN COPx COPy T Note penalty vidObj secn n config vddist;

% File path for saving raw COP data
Path = 'C:\Users\caspian.bell\West Point\CME - Postural Control Research Group - Data\ForcePlate';

% File path for sheet to contain all trial information
trialsheetlocation='C:\Users\caspian.bell\West Point\CME - Postural Control Research Group - Data\DataCollectionSheets\Trial Sheet.xlsx';


% File location for excell for parameters to be added into
datalocation="C:\Users\caspian.bell\West Point\CME - Postural Control Research Group - Data\ForcePlate\MetricData.xlsx";

% Take user input to determine subject data if specified
SubjID=strcat('Subj',input('Enter Subject ID #: ','s'));
subjboolean=input('Do you want to input subject data (y/n)? ','s')=='y';
if subjboolean
    H_ankle=input('Enter ankle IMU height: ');
    H_lowerback=input('Enter lowerback IMU height: ');
    H_sternum=input('Enter sternum IMU height: ');  
    H_head=input('Enter head IMU height: ');
end

% Randomly determines the starting conditions for each of the three tests
InitialCondition=randi([0 1],1,3);
if InitialCondition(1)==0
    disp('Initial PA test is with hard surface, click any button to continue.')
    IC_PA='Hard';
    PA1='HS';
    PA2='SS';
else  
    disp('Initial PA test is with foam surface, click any button to continue.')
    IC_PA='Foam';
    PA1='SS';
    PA2='HS';
end
pause
if InitialCondition(2)==0
    IC_PS='Hard';    
    PS1='HS';   
    PS2='SS';
else  
    IC_PS='Foam';    
    PS1='SS';
    PS2='HS';
end
if InitialCondition(3)==0
    IC_DS='Hard';    
    DS1='HS';
    DS2='SS';
else  
    IC_DS='Foam';    
    DS1='SS';
    DS2='HS';
end


% Creates new subject folder in the teams folder
folder=fullfile(Path,SubjID);
mkdir(folder)

waitforbuttonpress
disp(IC_PA)
% Runs through each block runner trial

Block_Runner_Forceplate
FileName=strcat(SubjID,'_',PA1,'_trial','1');
FullFileName=fullfile(folder,FileName);
save(FullFileName,'COPx','COPy','T','penalty')
Block_Runner_PostProcessing(len, COPx, COPy, T,  penalty, n, config, vddist, SubjID, PA1, datalocation);

Block_Runner_Forceplate
FileName=strcat(SubjID,'_',PA1,'_trial','2');
FullFileName=fullfile(folder,FileName);
save(FullFileName,'COPx','COPy','T','penalty')
Block_Runner_PostProcessing(len, COPx, COPy, T,  penalty, n, config, vddist, SubjID, PA1, datalocation);

Block_Runner_Forceplate
FileName=strcat(SubjID,'_',PA1,'_trial','3');
FullFileName=fullfile(folder,FileName);
save(FullFileName,'COPx','COPy','T','penalty')
Block_Runner_PostProcessing(len, COPx, COPy, T,  penalty, n, config, vddist, SubjID, PA1, datalocation);

Block_Runner_Forceplate
FileName=strcat(SubjID,'_',PA2,'_trial','4');
FullFileName=fullfile(folder,FileName);
save(FullFileName,'COPx','COPy','T','penalty')
Block_Runner_PostProcessing(len, COPx, COPy, T,  penalty, n, config, vddist, SubjID, PA2, datalocation);

Block_Runner_Forceplate
FileName=strcat(SubjID,'_',PA2,'_trial','5');
FullFileName=fullfile(folder,FileName);
save(FullFileName,'COPx','COPy','T','penalty')
Block_Runner_PostProcessing(len, COPx, COPy, T,  penalty, n, config, vddist, SubjID, PA2, datalocation);

Block_Runner_Forceplate
FileName=strcat(SubjID,'_',PA2,'_trial','6');
FullFileName=fullfile(folder,FileName);
save(FullFileName,'COPx','COPy','T','penalty')
Block_Runner_PostProcessing(len, COPx, COPy, T,  penalty, n, config, vddist, SubjID, PA2, datalocation);

% Informs user inital surface condition for postural stability test
if InitialCondition(2)==0
    disp('The initial PS test is with hard surface.')
else  
    disp('The initial PS test is with foam surface.')
end


%Takes user comments about trial
comment=input('Enter any comments for this subject','s');

% Updates data collection sheet if subject data was entered
if Subjboolean
    newtrial=table({SubjID},{comment},datetime,H_ankle,H_sternum,H_head,H_lowerback,{IC_PA},{IC_PS},{IC_DS});
    sheetname=trialsheetlocation;
    writetable(newtrial,sheetname,'WriteMode','Append',...
    'WriteVariableNames',false,'WriteRowNames',true) 
end