% ==============================================================================
%  AMTI Matlab Test Framework
% ==============================================================================
%  Copyright © 2017 Applied Mechanical Technology Incorporated
%
%  For private use of AMTI customers;  redistribution restricted.
% ==============================================================================

%
%  These are code snippets for the initialization and running of the AMTF
%
%  All of these can be found in the AMTIdataApp GUI application, and are pulled out
%  here for convenience of re-use by the target application
%

% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%  Snippet 1:  Call these at the very start of the application in the 'OpeningFcn'
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    %  Call the initialization to load the AMTI DLL
    status = DLLInitialize( true );
    if status == 0
        %  Fatal error: there's no DLL to attach to
        error('DLL not found - cannot run application');
    end
    
    %  Create the acquisition timer
	handles.AcquisitionTimer = timer;

    guidata(hObject, handles);
    
    %  Give the timer some normal parameters
    %  Note that the 'Period' variable can be set anywhere from 0.1 to 0.01
    set(handles.AcquisitionTimer, 'Name', 'Acquisition timer');
    set(handles.AcquisitionTimer, 'ExecutionMode', 'fixedRate');
    set(handles.AcquisitionTimer, 'Period', 0.03);
    set(handles.AcquisitionTimer, 'TimerFcn', { @DLLAcquisition, hObject } );

    guidata(hObject,handles);

    %  The polling loop will run, but no data will flow until things are initialized and started
    start(handles.AcquisitionTimer)



% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%  Snippet 2:  Call this when AMTI devices are attached and running
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    %
    %  Returns the number of active AMTI amp/platform pairs
    %  -1 for error status
    %
    nDevices = DLLStartup();
    
    %  A loop to get the model/SN of each device pair
    if ( nDevices > 0 )
        for i = 1 : nDevices
        	[ AmpModel,  AmpSN  ] = DLLGetAmpID( i );
        	[ PlatModel, PlatSN ] = DLLGetPlatformID( i );
        end
    end
    


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%  Snippet 3:  Call when the application is ready for data to flow from the AMTI devices
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    %  Call the DLL zero command to set all amp hardware to zero values
    %  This is generally advisable before any data collection starts
    %   and should be done (of course) with the platforms unloaded
    DLLZero();
    
    %  Call the DLL start command
    DLLCollecting( true );
     
    %  That's all there is to it!  The application should be ready for the function
    %  DataCollectionCallback() to be called repeatedly with a pointer and size value
    %  of one or more data packets

     
    %  To stop data collection:
    DLLCollecting( false );
     
    %  Keep in mind that some data may still come in after the stop command is issued,
    %  so it's best to keep the data collection going for a few hunderd msec
    


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%  Snippet 4:  Various calls to read and/or write collection parameters
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    %  NB!  All of the enumerated parameters defined in the AMTI SDK Manual have values
    %       shifted up by one for better compatibility with MatLab
    %
    %   Parameter               Value range          C++ values          MatLab values
    %
    %   Amplifier gain          500 - 4000            0 - 3               1 - 4
    %   Amplifier excitation    2.5v - 10v            0 - 2               1 - 3
    %   Run mode (units)        Met uncond - Bits     0 - 4               1 - 5
    %   Genlock mode            Off - Falling edge    0 - 2               1 - 3
    
    %
    %  Example code for access to amp parameters
    %

    %  Set the acquisition rate to 1200Hz
    DLLAcquisitionRate( 1200 );
    
    
    %  Set the run mode to Metric Conditioned
    DLLRunMode( 2 );

    
    %  Set the amp gain to 1000x on amp index 1 on channel 3 (Fz)
    %  NB: Excitation and gains are set on all channels at once
    gnarray = DLLGains( 1 );
    gnarray( 3 ) = 2;
    DLLGains( 1, exarray );

    %  Set the excitation voltage to 10 volts on amp index 1 on channel 5 (My)
    exarray = DLLExcitations( amp );
    exarray( 5 ) = 3;
    DLLExcitations( amp, exarray );



