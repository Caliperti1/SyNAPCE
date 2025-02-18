function Stability_Test_Forceplate(ID,surface,stance)


% Define global variables for game
global Data acc;

%Initialize parameters
acc=0;
Data = zeros(1,3);
% Get screen size
screen = get(0,'screensize');

% Define global parameters for force plate interaction
global DLLInterface;
global DataHandler;
% global hscat;
 
% Initialize the force plate
status = DLLInitialize(true);
if status == 0
    % Fatal error: there's no DLL to attach to
    error('DLL not found - cannot run application');
end
 
% Start up the dynamic linked library
status = DLLStartup();
DataHandler.DeviceCount = status;
if ( status < 0 )
    % Show error
    disp('Cannot start DLL');    
else
    disp('DLL initialized');    
    % Show the device count
    numstring = sprintf(' %d',status);
    disp(numstring)
    % Set up the device list
    if ( status > 0 )
        titles = cell( 1, status );
        for i = 1 : status
            [ ~, AmpSN ]  = DLLGetAmpID( i );
            [ model, PlatSN ] = DLLGetPlatformID( i );
            tstr = sprintf( ' %d:  %-6s%-24s%s', i, AmpSN, model, PlatSN );
            titles{1,i} = tstr;
        end
    else
        titles = '     ';
    end
    disp(titles);
end
if ( status > 0 )
    CurrentAmp = 1;
else
    CurrentAmp = 0;
end
 
% Set everything up here so as to minimize processing during live data collection
if ~DLLInterface.Running
    
    % Set up data collection
    DataHandler.PacketCount = 0;
    DataHandler.LastIndex = 0;
    DataHandler.DataCount = 0;
    DataHandler.DataPointer = 1;
    DataHandler.AmpOffset = CurrentAmp - 1;
    DataHandler.BufferPoints = 10000;      %  NB: Must be a multiple of 16
 
    % Build the mask for data copying during collection
    ndev = DataHandler.DeviceCount;
    aoff = DataHandler.AmpOffset;
    DataHandler.DataMask = false( 1, ndev * 8 * 16 );
 
    % Set up all channels as active
    nactive = 6;
    DataHandler.DataMask( aoff*8 + 2 : 8*ndev : 128*ndev ) = true;
    DataHandler.DataMask( aoff*8 + 3 : 8*ndev : 128*ndev ) = true;
    DataHandler.DataMask( aoff*8 + 4 : 8*ndev : 128*ndev ) = true;
    DataHandler.DataMask( aoff*8 + 5 : 8*ndev : 128*ndev ) = true;
    DataHandler.DataMask( aoff*8 + 6 : 8*ndev : 128*ndev ) = true;
    DataHandler.DataMask( aoff*8 + 7 : 8*ndev : 128*ndev ) = true;
 
    DataHandler.ActiveChannels = nactive;
    DataHandler.DataLength = nactive * 16;
 
    DataHandler.BufferSize = DataHandler.BufferPoints * nactive;
    DataHandler.Buffer = zeros( 1, DataHandler.BufferSize );
 
    % Call the DLL start command
    DLLCollecting(true);
 
    disp('Connected');
else
    % Call the DLL stop command
    DLLCollecting(false);
    pause( 0.2 );
 
    disp('Connected');
end
 
% Interface to data collection
DataHandler.Initialized = true;
DataHandler.CallbackCount = 0;
DataHandler.CallbackList = [];
DataHandler.PacketCount = 0;
DataHandler.ActiveChannels = 0;
DataHandler.FzCutoff = 1;
DataHandler.Sample = zeros(1,6);
DataHandler.COP.X = 0;
DataHandler.COP.Y = 0;
 
% Timer creation for data acquisition polling 
handles.AcquisitionTimer = timer;

% % Set up plot [USE FOR DEVELOPMENT AND BASIC TROUBLESHOOTING]
% figure(1)
% hscat = scatter(0,0,'filled');
% xlim([-0.5 0.5])
% ylim([-0.5 0.5])

 %vidObj = VideoWriter('Block_Runner_Demo'); % Create a video object to write frames to
 %vidObj.FrameRate = 24; % Specify the frame rate of the video
 %vidObj.Quality = 100; % Specify the quality (resolution) of the video (100 is best)
 %open(vidObj) % Open the video for writing 

%  Creates a figure of a dot on a second monitor 
dot=figure(1);
p = get(0, "MonitorPositions");
dot.Position(1) = p(2,1);
dot.WindowState = "maximized";
plot(0,0,'ob','LineWidth',20)
disp(strcat('Ready to begin ',surface,' ',stance,' trial.'))

% User begins data collection by pressing a button
waitforbuttonpress
disp('çollecting data')

%Starts the time
tic

% This is where the juicy stuff actually happens
set(handles.AcquisitionTimer, 'Name', 'Acquisition timer');
set(handles.AcquisitionTimer, 'ExecutionMode', 'fixedRate');
set(handles.AcquisitionTimer, 'Period', 0.03);
set(handles.AcquisitionTimer, 'TimerFcn', {@DLLAcquisition_Block_Runner});

start(handles.AcquisitionTimer)

% Pauses until user hits a key to end data collection
pause
disp('Trial ended')
% Close things down
% close(vidObj) % Close the video object once simulation is complete
tmrs = [handles.AcquisitionTimer];
for tmr = tmrs
    if tmr.Running
        stop(tmr);
        pause( 0.3 );
    end
    delete(tmr);
end
disp('Closing down the application');
DLLInitialize(false);

FileName=strcat(ID,'_',stance,'_',surface);
FullFileName=fullfile(folder,FileName);
save(FullFileName,'Data')
