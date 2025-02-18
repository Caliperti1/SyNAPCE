% ==============================================================================
%  AMTI Matlab Test Framework
% ==============================================================================
%  Copyright © 2017 Applied Mechanical Technology Incorporated
%
%  For private use of AMTI customers;  redistribution restricted.
% ==============================================================================

function varargout = AMTIdataApp_Test(varargin)
% AMTIDATAAPP MATLAB code for AMTIdataApp.fig
%      AMTIDATAAPP, by itself, creates a new AMTIDATAAPP or raises the existing
%      singleton*.
%
%      H = AMTIDATAAPP returns the handle to a new AMTIDATAAPP or the handle to
%      the existing singleton*.
%
%      AMTIDATAAPP('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in AMTIDATAAPP.M with the given input arguments.
%
%      AMTIDATAAPP('Property','Value',...) creates a new AMTIDATAAPP or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before AMTIdataApp_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to AMTIdataApp_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help AMTIdataApp

% Last Modified by GUIDE v2.5 12-May-2017 16:35:36

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       'AMTIdataApp', ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @AMTIdataApp_OpeningFcn, ...
                   'gui_OutputFcn',  @AMTIdataApp_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

end

% --- Executes just before AMTIdataApp is made visible.
function AMTIdataApp_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to AMTIdataApp (see VARARGIN)

    % Choose default command line output for AMTIdataApp
    handles.output = hObject;

    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes AMTIdataApp wait for user response (see UIRESUME)
    % uiwait(handles.AMTIDataApp);

    status = DLLInitialize( true );
    if status == 0
        %  Fatal error: there's no DLL to attach to
        error('DLL not found - cannot run application');
    end
    
    %
    %  GUI state
    %
    global DisplayHandler;
    
    DisplayHandler.Active = false;
    DisplayHandler.GraphClear = false;
    DisplayHandler.GraphActive = false;
    DisplayHandler.UpdateCount = 0;
    DisplayHandler.CurrentAmp = 0;

    %  Menu control values
    DisplayHandler.ChannelSelected = 0;
    DisplayHandler.Rate = 0;
    DisplayHandler.GenlockMode = 0;
    DisplayHandler.SampleTime = 10;
    DisplayHandler.Dimensions = zeros(1,2);
    DisplayHandler.Offsets = zeros(1,3);
    DisplayHandler.CableLength = 0;
    DisplayHandler.Rotation = 0;
    DisplayHandler.RunMode = 0;
    DisplayHandler.Ymax = 300;
    DisplayHandler.Ymin = -300;
    
    %  Start with Fz only selected
    DisplayHandler.FxSelected = false;
    DisplayHandler.FySelected = false;
    DisplayHandler.FzSelected = true;
    DisplayHandler.MxSelected = false;
    DisplayHandler.MySelected = false;
    DisplayHandler.MzSelected = false;
    
    %  Start with default values for channel data display
    DisplayHandler.ChannelUnits = [ 20, 20, 50, 100, 100, 50 ];
    DisplayHandler.ChannelOffsets = [ 200, 100, 0, -100, -200, -250 ];
    
    DisplayHandler.GraphColors = zeros( 3, 6 );
    DisplayHandler.GraphScales = ones( 1, 6 );
    DisplayHandler.GraphOffsets = zeros( 1, 6 );
    
    %  Get colors from the channel selection buttons
    h = findobj( 'tag', 'FxSelector' );
    DisplayHandler.ChannelColors(:,1) = get( h, 'BackgroundColor' );
    h = findobj( 'tag', 'FySelector' );
    DisplayHandler.ChannelColors(:,2) = get( h, 'BackgroundColor' );
    h = findobj( 'tag', 'FzSelector' );
    DisplayHandler.ChannelColors(:,3) = get( h, 'BackgroundColor' );
    h = findobj( 'tag', 'MxSelector' );
    DisplayHandler.ChannelColors(:,4) = get( h, 'BackgroundColor' );
    h = findobj( 'tag', 'MySelector' );
    DisplayHandler.ChannelColors(:,5) = get( h, 'BackgroundColor' );
    h = findobj( 'tag', 'MzSelector' );
    DisplayHandler.ChannelColors(:,6) = get( h, 'BackgroundColor' );
    
    DisplayHandler.NPoints = 450;
    DisplayHandler.PointBuffer = zeros( 6, DisplayHandler.NPoints );

    %  Display name vectors
    DisplayHandler.ChannelNames = { 'Fx', 'Fy', 'Fz', 'Mx', 'My', 'Mz' };
    DisplayHandler.ExcitationNames = { '2.5', '5', '10' };
    DisplayHandler.GainNames = { '500', '1000', '2000', '4000' };
    DisplayHandler.GenlockNames = { 'Off', 'Rising edge', 'Falling edge' };
    DisplayHandler.RunmodeNames = { 'Metric uncond', 'Metric cond', 'English uncond', 'English cond', 'Bit units' };
    
    %
    %  Interface to data collection
    %
    global DataHandler;
    
    DataHandler.Initialized = true;
    DataHandler.CallbackCount = 0;
    DataHandler.CallbackList = [];
    DataHandler.PacketCount = 0;
    DataHandler.ActiveChannels = 0;
    DataHandler.FzCutoff = 1;
    
    DataHandler.Sample = zeros(1,6);
    
    DataHandler.COP.X = 0;
    DataHandler.COP.Y = 0;
    
    DataHandler.BufferPoints = 10000;      %  NB: Must be a multiple of 16
    
    %
    %  Timer creation
    %
    %  There are two timers:  one for data acquisition polling, and one for screen updating
    %
    
    %  Create the screen update timer
	handles.UpdateTimer = timer;

	%  And the acquisition timer
	handles.AcquisitionTimer = timer;

    guidata(hObject, handles);

    %  Start the timers
    set(handles.UpdateTimer, 'Name', 'Screen update timer');
    set(handles.UpdateTimer, 'ExecutionMode', 'fixedRate');
    set(handles.UpdateTimer, 'Period', 0.05);
    set(handles.UpdateTimer, 'TimerFcn', {@UpdateScreen,hObject} );

    set(handles.AcquisitionTimer, 'Name', 'Acquisition timer');
    set(handles.AcquisitionTimer, 'ExecutionMode', 'fixedRate');
    set(handles.AcquisitionTimer, 'Period', 0.03);
    set(handles.AcquisitionTimer, 'TimerFcn', {@DLLAcquisition,hObject} );

    guidata(hObject,handles);

    start(handles.UpdateTimer)
    start(handles.AcquisitionTimer)
    
end

% --- Outputs from this function are returned to the command line.
function varargout = AMTIdataApp_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    % Get default command line output from handles structure
    varargout{1} = handles.output;

end

% --- Executes when user attempts to close AMTIDataApp.
function AMTIDataApp_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to AMTIDataApp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    tmrs = [handles.UpdateTimer, handles.AcquisitionTimer];
    for tmr = tmrs
        if tmr.Running
            stop(tmr);
            pause( 0.3 );
        end
        delete(tmr);
    end
	
    fprintf('Closing down the application\n');
    
    DLLInitialize( false );

    % Hint: delete(hObject) closes the figure
    delete(hObject);

end


%================================================================
%  Screen update support
%================================================================

%  This timer-based routine handles all dynamic screen updates
function UpdateScreen(~,~,hObject)
    global DataHandler;
    global DisplayHandler;

    DisplayHandler.UpdateCount = DisplayHandler.UpdateCount+1;

    handles = guidata(hObject);

    %  Show the packet count
    numstring = sprintf('%d ',DataHandler.PacketCount);
    set(handles.Data_Npackets, 'string', numstring);

    %  Show the FzUnit value
    numstring = sprintf('%6.2f ',DataHandler.Sample(3));
    set(handles.Data_Fz, 'string', numstring);
    
    %  Show the COP values
    if ( mod( DisplayHandler.UpdateCount, 4 ) == 0 )
        numstring = sprintf('%6.2f ',DataHandler.COP.X);
        set(handles.COP_X, 'string', numstring);
        numstring = sprintf('%6.2f ',DataHandler.COP.Y);
        set(handles.COP_Y, 'string', numstring);
    end
    DataHandler.COP.X
    
    %  If it's time to clear the graph, do so
    if DisplayHandler.GraphClear
        UpdateGraph(handles.DataDisplay, 0);
        DisplayHandler.GraphClear = false;
    end
    
    %  If the graph is active, update it
    if DisplayHandler.GraphActive
        UpdateGraph(handles.DataDisplay, 1);
    end

end

%  Update the data graph based on incoming data
function UpdateGraph(ghnd, state)
    global DisplayHandler;

    %  Clear when requested at the start of data acquisition
    if ( state == 0 )

        cla( ghnd );
        
        set( ghnd, 'YLim', [ DisplayHandler.Ymin, DisplayHandler.Ymax ] );
        set( ghnd, 'YLimMode', 'manual' );
        set( ghnd, 'XLim', [ 1, DisplayHandler.NPoints ] );
        set( ghnd, 'XLimMode', 'manual' );
        
        DisplayHandler.PointIndex = 1;
        DisplayHandler.Shuffle = false;
        DisplayHandler.DataCount = 0;
        DisplayHandler.Remainder = 0;
        DisplayHandler.DataPointer = 1;
        DisplayHandler.Xaxis = 1:DisplayHandler.NPoints;
        DisplayHandler.Yaxis = zeros(6,DisplayHandler.NPoints);
        for c = 1 : 6
            DisplayHandler.Yaxis(c,:) = DisplayHandler.GraphOffsets(c);
        end
        
        return;
    end
    
    %  If we're updating, see what data has come in since the last check
	global DataHandler;
    
    newDataCount = DataHandler.DataCount;
    updateDataCount = ( newDataCount - DisplayHandler.DataCount ) + DisplayHandler.Remainder;
    DisplayHandler.DataCount = newDataCount;
    
    updatePointCount = floor( updateDataCount / DisplayHandler.PointRatio );
    
    DisplayHandler.Remainder = updateDataCount - ( updatePointCount * DisplayHandler.PointRatio );
    
    if ( updatePointCount == 0 )
        return;
    end

    %  Copy the data from the collection buffer
    di = DisplayHandler.DataPointer;
    for i = 1 : updatePointCount
        for c = 1 : DataHandler.ActiveChannels
            DisplayHandler.PointBuffer(c,i) = DataHandler.Buffer(di+(c-1)) * DisplayHandler.GraphScales(c) + DisplayHandler.GraphOffsets(c);
        end
        di = di + DisplayHandler.PointRatio;
        if ( di > DataHandler.BufferSize )
            di = di - DataHandler.BufferSize;
        end
    end
    DisplayHandler.DataPointer = di;

    %  Update the graphics buffer
	if ( DisplayHandler.Shuffle )
        %  We've filled the buffer, so we have to move the data down and add to the end
        DisplayHandler.Yaxis(:,1:DisplayHandler.NPoints-updatePointCount) = DisplayHandler.Yaxis(:,updatePointCount+1:DisplayHandler.NPoints);
        pointIndex = ( DisplayHandler.NPoints + 1 ) - updatePointCount;
    else
        %  We're still filling the buffer
        newPointIndex = DisplayHandler.PointIndex + updatePointCount;
        if ( newPointIndex > DisplayHandler.NPoints )
            %  Now we're filled up, so start the shuffling process
            DisplayHandler.Shuffle = true;
            offset = (newPointIndex-1) - DisplayHandler.NPoints;
            if ( offset > 0 )
                DisplayHandler.Yaxis(:,1:DisplayHandler.NPoints-offset) = DisplayHandler.Yaxis(:,offset+1:DisplayHandler.NPoints);
            end
           	pointIndex = ( DisplayHandler.NPoints + 1 ) - updatePointCount;
            DisplayHandler.PointIndex = DisplayHandler.NPoints + 1;
        else
            pointIndex = DisplayHandler.PointIndex;
            DisplayHandler.PointIndex = newPointIndex;
        end
	end
    
    if ( pointIndex < 0 )
        fprintf( 'Internal indexing error\n' );
    end
    
    %  Add new points
    DisplayHandler.Yaxis(:,pointIndex:pointIndex+(updatePointCount-1)) = DisplayHandler.PointBuffer(:,1:updatePointCount);
        
    %  Do the plot
	switch DataHandler.ActiveChannels
        case 1
            h = plot( ghnd, DisplayHandler.Xaxis, DisplayHandler.Yaxis(1,:) );
            h(1).Color = DisplayHandler.GraphColors(:,1);
        case 2
            h = plot( ghnd, DisplayHandler.Xaxis, DisplayHandler.Yaxis(1,:), DisplayHandler.Xaxis, DisplayHandler.Yaxis(2,:) );
            h(1).Color = DisplayHandler.GraphColors(:,1);
            h(2).Color = DisplayHandler.GraphColors(:,2);
        case 3
            h = plot( ghnd, DisplayHandler.Xaxis, DisplayHandler.Yaxis(1,:), DisplayHandler.Xaxis, DisplayHandler.Yaxis(2,:), DisplayHandler.Xaxis, DisplayHandler.Yaxis(3,:) );
            h(1).Color = DisplayHandler.GraphColors(:,1);
            h(2).Color = DisplayHandler.GraphColors(:,2);
            h(3).Color = DisplayHandler.GraphColors(:,3);
        case 4
            h = plot( ghnd, DisplayHandler.Xaxis, DisplayHandler.Yaxis(1,:), DisplayHandler.Xaxis, DisplayHandler.Yaxis(2,:), DisplayHandler.Xaxis, DisplayHandler.Yaxis(3,:), DisplayHandler.Xaxis, DisplayHandler.Yaxis(4,:) );
            h(1).Color = DisplayHandler.GraphColors(:,1);
            h(2).Color = DisplayHandler.GraphColors(:,2);
            h(3).Color = DisplayHandler.GraphColors(:,3);
            h(4).Color = DisplayHandler.GraphColors(:,4);
        case 5
            h = plot( ghnd, DisplayHandler.Xaxis, DisplayHandler.Yaxis(1,:), DisplayHandler.Xaxis, DisplayHandler.Yaxis(2,:), DisplayHandler.Xaxis, DisplayHandler.Yaxis(3,:), DisplayHandler.Xaxis, DisplayHandler.Yaxis(4,:), DisplayHandler.Xaxis, DisplayHandler.Yaxis(5,:) );
            h(1).Color = DisplayHandler.GraphColors(:,1);
            h(2).Color = DisplayHandler.GraphColors(:,2);
            h(3).Color = DisplayHandler.GraphColors(:,3);
            h(4).Color = DisplayHandler.GraphColors(:,4);
            h(5).Color = DisplayHandler.GraphColors(:,5);
        otherwise
            h = plot( ghnd, DisplayHandler.Xaxis, DisplayHandler.Yaxis(1,:), DisplayHandler.Xaxis, DisplayHandler.Yaxis(2,:), DisplayHandler.Xaxis, DisplayHandler.Yaxis(3,:), DisplayHandler.Xaxis, DisplayHandler.Yaxis(4,:), DisplayHandler.Xaxis, DisplayHandler.Yaxis(5,:), DisplayHandler.Xaxis, DisplayHandler.Yaxis(6,:) );
            h(1).Color = DisplayHandler.GraphColors(:,1);
            h(2).Color = DisplayHandler.GraphColors(:,2);
            h(3).Color = DisplayHandler.GraphColors(:,3);
            h(4).Color = DisplayHandler.GraphColors(:,4);
            h(5).Color = DisplayHandler.GraphColors(:,5);
            h(6).Color = DisplayHandler.GraphColors(:,6);
	end
    
    set( ghnd, 'XLim', [ 1, DisplayHandler.NPoints  ], 'XLimMode', 'manual' );
    set( ghnd, 'YLim', [ DisplayHandler.Ymin, DisplayHandler.Ymax ], 'YLimMode', 'manual' );
    set( ghnd, 'YTickLabel', {}, 'XTickLabel', {} );
    set( ghnd, 'YTick', [ -200, -100, 0, 100, 200 ] );

end

%  Initialize the menu items for general usage
function InitializeGeneralDisplay( status )

    global DisplayHandler;

    %  Get current acquisition values from the DLL
    DisplayHandler.Rate = DLLAcquisitionRate();
    DisplayHandler.GenlockMode = DLLGenlockMode();
    DisplayHandler.RunMode = DLLRunMode();

    acqh = findobj( 'tag', 'AcquisitionMenu' );

    %  Set the acquisition rate menu item
    arh = findobj( acqh, 'tag', 'RateSelection' );
    h = findobj( arh, 'tag', 'RateValue' );
    ratestring = sprintf( '%d', DisplayHandler.Rate );
    set( h, 'Label', ratestring );
    
    %  Set the genlock menu item
    glh = findobj( acqh, 'tag', 'GenlockSelection' );
	for m = 1 : 3
        mlab = DisplayHandler.GenlockNames{m};
        h = findobj( glh, 'Label', mlab );
        if ( m == DisplayHandler.GenlockMode )
        	set( h, 'Checked', 'On' );
        else
        	set( h, 'Checked', 'Off' );
        end
	end

    %  Set the acquisition time menu item
    sth = findobj( acqh, 'tag', 'SampleTimeSelection' );
    h = findobj( sth, 'tag', 'SampleTimeValue' );
    timestring = sprintf( '%d', DisplayHandler.SampleTime );
    set( h, 'Label', timestring );

    %  Set the run mode menu item
    rmh = findobj( acqh, 'tag', 'RunModeSelection' );
    for m = 1 : 5
        mlab = DisplayHandler.RunmodeNames{m};
        h = findobj( rmh, 'Label', mlab );
        if ( m == DisplayHandler.RunMode )
        	set( h, 'Checked', 'On' );
        else
        	set( h, 'Checked', 'Off' );
        end
    end
    
    %  Set the units/division menu items
    dmh = findobj( 'tag', 'DisplayMenu' );
    for c = 1:6
        dvh = findobj( dmh, 'tag', DisplayHandler.ChannelNames{c} );
        duh = findobj( dvh, 'tag', 'DisplayUnitValue' );
        unitstring = sprintf( '%d', DisplayHandler.ChannelUnits(c) );
        set( duh, 'Label', unitstring );
    end

    h = findobj( 'tag', 'FxSelector' );
    set( h, 'Value', DisplayHandler.FxSelected );
    h = findobj( 'tag', 'FySelector' );
    set( h, 'Value', DisplayHandler.FySelected );
    h = findobj( 'tag', 'FzSelector' );
    set( h, 'Value', DisplayHandler.FzSelected );
    h = findobj( 'tag', 'MxSelector' );
    set( h, 'Value', DisplayHandler.MxSelected );
    h = findobj( 'tag', 'MySelector' );
    set( h, 'Value', DisplayHandler.MySelected );
    h = findobj( 'tag', 'MzSelector' );
    set( h, 'Value', DisplayHandler.MzSelected );
    
	global DataHandler;
	if ( nargin == 1 )
        %  Clear collection data
        DataHandler.DeviceCount = status;

        DataHandler.DataCount = 0;
        DataHandler.Sample = zeros(1,6);
    
        DataHandler.COP.X = 0;
        DataHandler.COP.Y = 0;
        
        h = findobj( 'tag', 'AcquisitionMenu' );
        set( h, 'Visible', 'on' );
        h = findobj( 'tag', 'DisplayMenu' );
        set( h, 'Visible', 'on' );
	end
    
end

%  Initialize the menu items for amplifier-specific usage
function InitializeAmpDisplay( index )

    global DisplayHandler;

    %  Set the amplifier configuration menus visibility
    exh = findobj( 'tag', 'ExcitationMenu' );
	gnh = findobj( 'tag', 'GainMenu' );
    plh = findobj( 'tag', 'PlatformMenu' );
    amh = findobj( 'tag', 'AmplifierMenu' );
    
    DisplayHandler.CurrentAmp = index;

    if ( index == 0 )
        %  No active amplifier, so turn some things off
        set(exh,'Visible','off');
        set(gnh,'Visible','off');
        set(plh,'Visible','off');
        set(amh,'Visible','off');
        DisplayHandler.Active = false;
    else
        if ( ~DisplayHandler.Active )
            set(exh,'Visible','on');
            set(gnh,'Visible','on');
            set(plh,'Visible','on');
            set(amh,'Visible','on');
            DisplayHandler.Active = true;
        end
        
        %  We have an active amplifier, so set its various parameters
        excitations = DLLExcitations( DisplayHandler.CurrentAmp );
        gains = DLLGains( DisplayHandler.CurrentAmp );
        
        for c = 1 : 6
            ctag = DisplayHandler.ChannelNames{c};

            %  Set excitation values
            chh = findobj( exh, 'tag', ctag );
            n = excitations(c);
            for e = 1 : 3
                elab = DisplayHandler.ExcitationNames{e};
                h = findobj( chh, 'Label', elab );
                if ( e == n )
                    set( h, 'Checked', 'On' );
                else
                    set( h, 'Checked', 'Off' );
                end
            end
            
            %  Set gain values
            chh = findobj( gnh, 'tag', ctag );
            n = gains(c);
            for g = 1 : 4
                glab = DisplayHandler.GainNames{g};
                h = findobj( chh, 'Label', glab );
                if ( g == n )
                    set( h, 'Checked', 'On' );
                else
                    set( h, 'Checked', 'Off' );
                end
            end
        end
        
        %  Set the platform parameters as well
        DisplayHandler.Dimensions = DLLPlatformLengthAndWidth( DisplayHandler.CurrentAmp );
        dimtext = sprintf( '%5.2f, %5.2f', DisplayHandler.Dimensions(1), DisplayHandler.Dimensions(2) );
        dmh = findobj( 'tag', 'DimensionValues' );
        set( dmh, 'Label', dimtext );
        
        DisplayHandler.Offsets = DLLPlatformXYZOffsets( DisplayHandler.CurrentAmp );        
        offtext = sprintf( '%5.2f, %5.2f, %5.2f', DisplayHandler.Offsets(1), DisplayHandler.Offsets(2), DisplayHandler.Offsets(3) );
        ofh = findobj( 'tag', 'OffsetValues' );
        set( ofh, 'Label', offtext );
        
        DisplayHandler.CableLength = DLLCableLength( DisplayHandler.CurrentAmp );
        cltext = sprintf( '%5.2f', DisplayHandler.CableLength );
        clh = findobj( 'tag', 'CableLengthValue' );
        set( clh, 'Label', cltext );
        
        DisplayHandler.Rotation = DLLPlatformRotation( DisplayHandler.CurrentAmp );
        rotext = sprintf( '%5.2f', DisplayHandler.Rotation );
        roh = findobj( 'tag', 'RotationValue' );
        set( roh, 'Label', rotext );
    end
end


%================================================================
%  Button controls
%================================================================

% --- Executes on button press in Button_Initialize.
function Button_Initialize_Callback(hObject, eventdata, handles)

    status = DLLStartup();

    if ( status < 0 )
    	%  Show error
        h = findobj( 'tag', 'Data_Status' );
        set(h,'String','Cannot start DLL');    
    else
        h = findobj( 'tag', 'Data_Status' );
        set(h,'String','DLL initialized');    

        %  Show the device count
        h = findobj( 'tag', 'Data_Namps' );
        numstring = sprintf(' %d',status);
        set(h,'String',numstring);
        
        %  And set up the device list
        mhnd = findobj( 'tag', 'DisplayActive' );
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
        set( mhnd, 'String', titles );
        
        %  Enable the action buttons
        h = findobj( 'tag', 'Button_Reset' );
        set( h, 'Enable', 'on' );
        h = findobj( 'tag', 'Button_Save' );
        set( h, 'Enable', 'on' );

        %  Set the configuration values
        if ( status > 0 )
            h = findobj( 'tag', 'Button_Start' );
            set( h, 'Enable', 'on' );
            h = findobj( 'tag', 'Button_Zero' );
            set( h, 'Enable', 'on' );
            h = findobj( 'tag', 'Button_Blink' );
            set( h, 'Enable', 'on' );
            
            InitializeAmpDisplay( 1 );
        else
            h = findobj( 'tag', 'Button_Start' );
            set( h, 'Enable', 'off' );
            h = findobj( 'tag', 'Button_Zero' );
            set( h, 'Enable', 'off' );
            h = findobj( 'tag', 'Button_Blink' );
            set( h, 'Enable', 'off' );

            InitializeAmpDisplay( 0 );
        end
        
        InitializeGeneralDisplay(status);
    end

end

% --- Executes on button press in Button_Reset.
function Button_Reset_Callback(hObject, eventdata, ~)
    global DisplayHandler;
    DLLResetSoftware( DisplayHandler.CurrentAmp );
end

% --- Executes on button press in Button_Save.
function Button_Save_Callback(hObject, eventdata, handles)
    global DisplayHandler;
    DLLResetSoftware( DisplayHandler.CurrentAmp );
end

% --- Executes on button press in Button_Start.
function Button_Start_Callback(hObject, eventdata, handles)

    global DLLInterface;
    global DataHandler;
    global DisplayHandler;
   
    if ~DLLInterface.Running
        %
        %  Start collecting
        %  We set everything up here so as to minimize processing during live data collection
        %
        
        %  Set up collection data
        DataHandler.PacketCount = 0;
        DataHandler.LastIndex = 0;
        DataHandler.DataCount = 0;
        DataHandler.DataPointer = 1;
        DataHandler.AmpOffset = DisplayHandler.CurrentAmp - 1;

        %  Build the mask for data copying during collection
        ndev = DataHandler.DeviceCount;
        aoff = DataHandler.AmpOffset;
        
        DataHandler.DataMask = false( 1, ndev * 8 * 16 );
        nactive = 0;

        %  Check each channel and mark the active ones appropriately
        if DisplayHandler.FxSelected
            DataHandler.DataMask( aoff*8 + 2 : 8*ndev : 128*ndev ) = true;
            nactive = nactive + 1;
            DisplayHandler.GraphColors(:,nactive) = DisplayHandler.ChannelColors(:,1);
            DisplayHandler.GraphScales(nactive) = 100 / DisplayHandler.ChannelUnits(1);
            DisplayHandler.GraphOffsets(nactive) = DisplayHandler.ChannelOffsets(1);
        end
        if DisplayHandler.FySelected
            DataHandler.DataMask( aoff*8 + 3 : 8*ndev : 128*ndev ) = true;
            nactive = nactive + 1;
            DisplayHandler.GraphColors(:,nactive) = DisplayHandler.ChannelColors(:,2);
            DisplayHandler.GraphScales(nactive) = 100 / DisplayHandler.ChannelUnits(2);
            DisplayHandler.GraphOffsets(nactive) = DisplayHandler.ChannelOffsets(2);
        end
        if DisplayHandler.FzSelected
            DataHandler.DataMask( aoff*8 + 4 : 8*ndev : 128*ndev ) = true;
            nactive = nactive + 1;
            DisplayHandler.GraphColors(:,nactive) = DisplayHandler.ChannelColors(:,3);
            DisplayHandler.GraphScales(nactive) = 100 / DisplayHandler.ChannelUnits(3);
            DisplayHandler.GraphOffsets(nactive) = DisplayHandler.ChannelOffsets(3);
        end
        if DisplayHandler.MxSelected
            DataHandler.DataMask( aoff*8 + 5 : 8*ndev : 128*ndev ) = true;
            nactive = nactive + 1;
            DisplayHandler.GraphColors(:,nactive) = DisplayHandler.ChannelColors(:,4);
            DisplayHandler.GraphScales(nactive) = 100 / DisplayHandler.ChannelUnits(4);
            DisplayHandler.GraphOffsets(nactive) = DisplayHandler.ChannelOffsets(4);
        end
        if DisplayHandler.MySelected
            DataHandler.DataMask( aoff*8 + 6 : 8*ndev : 128*ndev ) = true;
            nactive = nactive + 1;
            DisplayHandler.GraphColors(:,nactive) = DisplayHandler.ChannelColors(:,5);
            DisplayHandler.GraphScales(nactive) = 100 / DisplayHandler.ChannelUnits(5);
            DisplayHandler.GraphOffsets(nactive) = DisplayHandler.ChannelOffsets(5);
        end
        if DisplayHandler.MzSelected
            DataHandler.DataMask( aoff*8 + 7 : 8*ndev : 128*ndev ) = true;
            nactive = nactive + 1;
            DisplayHandler.GraphColors(:,nactive) = DisplayHandler.ChannelColors(:,6);
            DisplayHandler.GraphScales(nactive) = 100 / DisplayHandler.ChannelUnits(6);
            DisplayHandler.GraphOffsets(nactive) = DisplayHandler.ChannelOffsets(6);
        end
        
        DataHandler.ActiveChannels = nactive;
        DataHandler.DataLength = nactive * 16;

        DataHandler.BufferSize = DataHandler.BufferPoints * nactive;
        DataHandler.Buffer = zeros( 1, DataHandler.BufferSize );

        %  Data decimation ratio
        DisplayHandler.PointRatio = round( ( DisplayHandler.Rate * DisplayHandler.SampleTime ) / DisplayHandler.NPoints ) * nactive;
        
        %  Set up screen for collecting data
        DisplayHandler.GraphClear = true;
        DisplayHandler.GraphActive = ( nactive > 0 );
        pause( 0.2 );

        %  Change button to Stop
        h = findobj( 'tag', 'Button_Start' );
        set(h,'String','Stop');

        %  Call the DLL start command
        DLLCollecting( true );

        h = findobj( 'tag', 'Data_Status' );
        set(h,'String','DLL collecting');
        
        fprintf('Starting data collection\n');
    else
        %  Call the DLL stop command
        DLLCollecting( false );
        pause( 0.2 );

        %  Set up screen for no collection
        DisplayHandler.GraphActive = false;
        
        %  Change button to Start
        h = findobj( 'tag', 'Button_Start' );
        set(h,'String','Start');

        h = findobj( 'tag', 'Data_Status' );
        set(h,'String','DLL initialized');
        
        fprintf('Stopping data collection\n');
    end    

end

% --- Executes on button press in Button_Zero.
function Button_Zero_Callback(hObject, eventdata, handles)
    DLLZero();
 end

% --- Executes on button press in Button_Blink.
function Button_Blink_Callback(hObject, eventdata, handles)
    global DisplayHandler;
    DLLBlink( DisplayHandler.CurrentAmp );
end


%================================================================
%  Display data controls
%================================================================

%  Executes on selection change in DisplayActive
function DisplayActive_Callback(hObject, eventdata, handles)
    n = get(hObject, 'Value');
    InitializeAmpDisplay( n );
end

%  Executes on a channel selector press
function ChanSelector_Callback(hObject, eventdata, handles)
    global DisplayHandler;
    
    switch get(hObject,'Tag')
        case 'FxSelector'
            DisplayHandler.FxSelected = ~DisplayHandler.FxSelected;
        case 'FySelector'
            DisplayHandler.FySelected = ~DisplayHandler.FySelected;
        case 'FzSelector'
            DisplayHandler.FzSelected = ~DisplayHandler.FzSelected;
        case 'MxSelector'
            DisplayHandler.MxSelected = ~DisplayHandler.MxSelected;
        case 'MySelector'
            DisplayHandler.MySelected = ~DisplayHandler.MySelected;
        case 'MzSelector'
            DisplayHandler.MzSelected = ~DisplayHandler.MzSelected;
    end
end


%================================================================
%  Menu controls
%================================================================

function Channel_Callback(hObject, eventdata, handles)
    global DisplayHandler;
    DisplayHandler.ChannelSelected = get( hObject, 'UserData' );
end

% ============  Excitation and Gain menus ============

function Excitation_Set_Callback(hObject, eventdata, handles)
    global DisplayHandler;
    
    value = get( hObject, 'UserData' );

    exarray = DLLExcitations( DisplayHandler.CurrentAmp );
    exarray( DisplayHandler.ChannelSelected ) = value;
    DLLExcitations( DisplayHandler.CurrentAmp, exarray );
    
    InitializeAmpDisplay( DisplayHandler.CurrentAmp );
end

function Gain_Set_Callback(hObject, eventdata, handles)
    global DisplayHandler;
    
    value = get( hObject, 'UserData' );
    gainarray = DLLGains( DisplayHandler.CurrentAmp );
    gainarray( DisplayHandler.ChannelSelected ) = value;
    DLLGains( DisplayHandler.CurrentAmp, gainarray );
    
    InitializeAmpDisplay( DisplayHandler.CurrentAmp );
end

% ============  Data acquisition menu ============

function RateValue_Callback(hObject, eventdata, handles)
    global DisplayHandler;

	DisplayHandler.Rate = DLLAcquisitionRate();
    rate_text = sprintf( '%d', DisplayHandler.Rate );
     
    %  Can we find out where the menu item is?
    % v = get( hObject );
    dh = findobj( 'tag', 'AMTIDataApp' );
    
    rrh = uicontrol( dh, 'Style', 'edit', 'Tag', 'RateEditorBox', 'Position', [150, 410, 50, 30 ], 'BackgroundColor', 'c', 'Callback', @RateChanged );
    set( rrh, 'String', rate_text );
end

function RateChanged(src,event)
    global DisplayHandler;
    
    rate_string = src.String;
    rate_value = str2double( rate_string );
    DisplayHandler.Rate = rate_value;
    DLLAcquisitionRate( DisplayHandler.Rate );
    InitializeGeneralDisplay();
  
    delete( src );
end

function Genlock_Set_Callback(hObject, eventdata, handles)
    value = get( hObject, 'UserData' );
    DLLGenlockMode( value );
    InitializeGeneralDisplay();
end

function SampleTimeValue_Callback(hObject, eventdata, handles)
    global DisplayHandler;

    time_text = sprintf( '%d', DisplayHandler.SampleTime );

    %  Can we find out where the menu item is?
    % v = get( hObject );
    dh = findobj( 'tag', 'AMTIDataApp' );
    
    tsh = uicontrol( dh, 'Style', 'edit', 'Tag', 'TimeEditorBox', 'Position', [150, 370, 50, 30 ], 'BackgroundColor', 'c', 'Callback', @TimeChanged );
    set( tsh, 'String', time_text );
end

function TimeChanged(src,event)
    global DisplayHandler;
    
    time_string = src.String;
    time_value = str2double( time_string );
    DisplayHandler.SampleTime = time_value;
    InitializeGeneralDisplay();
  
    delete( src );
end

function RunMode_Set_Callback(hObject, eventdata, handles)
    value = get( hObject, 'UserData' );
    DLLRunMode( value );
    InitializeGeneralDisplay();
end


% ============  Display parameters menu ============

function DisplayUnitValue_Callback(hObject, eventdata, handles)
    global DisplayHandler;

    units_text = sprintf( '%d', DisplayHandler.ChannelUnits( DisplayHandler.ChannelSelected ) );
     
    %  Can we find out where the menu item is?
    % v = get( hObject );
    dh = findobj( 'tag', 'AMTIDataApp' );
    
    ypos = 430 - 18 * DisplayHandler.ChannelSelected;
    duh = uicontrol( dh, 'Style', 'edit', 'Tag', 'UnitsEditorBox', 'Position', [230, ypos, 50, 30 ], 'BackgroundColor', 'c', 'Callback', @DisplayUnitsChanged );
    set( duh, 'String', units_text );
    
end

function DisplayUnitsChanged(src,event)

    global DisplayHandler;
    
    units_string = src.String;
    units_value = str2double( units_string );
    DisplayHandler.ChannelUnits( DisplayHandler.ChannelSelected ) = units_value;
    InitializeGeneralDisplay();
  
    delete( src );
end


function ZeroPositionValue_Callback(hObject, eventdata, handles)
    global DisplayHandler;
    
    current_val = DisplayHandler.ChannelOffsets(DisplayHandler.ChannelSelected);

    gph = findobj( 'tag', 'GraphPositionSlider' );
    set(gph,'BackgroundColor',DisplayHandler.ChannelColors(:,DisplayHandler.ChannelSelected));
    set(gph, 'Max',DisplayHandler.Ymax, 'Min', DisplayHandler.Ymin );
    set(gph,'Value',current_val);
    set(gph,'Visible','on');
    
    gph = findobj( 'tag', 'GraphPositionSet' );
    set(gph,'BackgroundColor',DisplayHandler.ChannelColors(:,DisplayHandler.ChannelSelected));
    set(gph,'Visible','on');
end

% --- Executes on slider movement.
function GraphPositionSlider_Callback(hObject, eventdata, handles)
    global DisplayHandler;
    pos = get(hObject,'Value');
    DisplayHandler.ChannelOffsets(DisplayHandler.ChannelSelected) = pos;
end

% --- Executes on button press in GraphPositionSet.
function GraphPositionSet_Callback(hObject, eventdata, handles)
    gph = findobj( 'tag', 'GraphPositionSlider' );
    set(gph,'Visible','off');
    gph = findobj( 'tag', 'GraphPositionSet' );
    set(gph,'Visible','off');
end


% ============  Platform parameters menu ============

function DimensionValues_Callback(hObject, eventdata, handles)
    global DisplayHandler;

	dims_text = sprintf( '%5.2f, %5.2f', DisplayHandler.Dimensions(1), DisplayHandler.Dimensions(2)  );
    
    dh = findobj( 'tag', 'AMTIDataApp' );
	dmh = uicontrol( dh, 'Style', 'edit', 'Tag', 'DimensionsEditorBox', 'Position', [220, 410, 100, 30 ], 'BackgroundColor', 'c', 'Callback', @DimensionsChanged );
	set( dmh, 'String', dims_text );
end

function DimensionsChanged(src,event)
	global DisplayHandler;
    str = src.String;
    if strfind( str, ',' )
        compos = find(str==',');
        xstr = str(1:compos-1);
        DisplayHandler.Dimensions(1) = str2double( xstr );
        ystr = str(compos+1:end);
        DisplayHandler.Dimensions(2) = str2double( ystr );
        DLLPlatformLengthAndWidth( DisplayHandler.CurrentAmp, DisplayHandler.Dimensions );
        ofh = findobj( 'tag', 'DimensionValues' );
        set( ofh, 'Label', str );
    end
	delete( src );
end

function OffsetValues_Callback(hObject, eventdata, handles)
    global DisplayHandler;

	offsets_text = sprintf( '%6.3f, %6.3f, %6.3f', DisplayHandler.Offsets(1), DisplayHandler.Offsets(2), DisplayHandler.Offsets(3) );
    
    dh = findobj( 'tag', 'AMTIDataApp' );
	ofh = uicontrol( dh, 'Style', 'edit', 'Tag', 'OffsetsEditorBox', 'Position', [220, 395, 120, 30 ], 'BackgroundColor', 'c', 'Callback', @OffsetsChanged );
	set( ofh, 'String', offsets_text );
end

function OffsetsChanged(src,event)
	global DisplayHandler;
	str = src.String;
	compos = find(str==',');
    if length(compos) == 2
        xstr = str(1:compos-1);
        ystr = str(compos(1)+1:compos(2)-1);
        zstr = str(compos(2)+1:end);
        DisplayHandler.Offsets(1) = str2double( xstr );
        DisplayHandler.Offsets(2) = str2double( ystr );
        DisplayHandler.Offsets(3) = str2double( zstr );
        DLLPlatformXYZOffsets( DisplayHandler.CurrentAmp, DisplayHandler.Offsets );
        ofh = findobj( 'tag', 'OffsetValues' );
        set( ofh, 'Label', str );
    end
	delete( src );
end

function CableLengthValue_Callback(hObject, eventdata, handles)
    global DisplayHandler;

	length_text = sprintf( '%5.2f', DisplayHandler.CableLength );
    
    dh = findobj( 'tag', 'AMTIDataApp' );
	csh = uicontrol( dh, 'Style', 'edit', 'Tag', 'CableLengthEditorBox', 'Position', [220, 380, 50, 30 ], 'BackgroundColor', 'c', 'Callback', @CableLengthChanged );
	set( csh, 'String', length_text );
end

function CableLengthChanged(src,event)
	global DisplayHandler;
    
	length_string = src.String;
    length_value = str2double( length_string );
    if ( length_value > 0 )
        DisplayHandler.CableLength = length_value;
        newlen = DLLCableLength( DisplayHandler.CurrentAmp, DisplayHandler.CableLength );
        cvh = findobj( 'tag', 'CableLengthValue' );
        set( cvh, 'Label', length_string );
    end
	delete( src );
end

function RotationValue_Callback(hObject, eventdata, handles)
    global DisplayHandler;

	rotation_text = sprintf( '%5.2f', DisplayHandler.Rotation );
    
    dh = findobj( 'tag', 'AMTIDataApp' );
	csh = uicontrol( dh, 'Style', 'edit', 'Tag', 'RotationEditorBox', 'Position', [220, 365, 50, 30 ], 'BackgroundColor', 'c', 'Callback', @RotationChanged );
	set( csh, 'String', rotation_text );
end

function RotationChanged(src,event)
	global DisplayHandler;
    
	rotation_string = src.String;
    rotation_value = str2double( rotation_string );
    DisplayHandler.Rotation = rotation_value;
    DLLPlatformRotation( DisplayHandler.CurrentAmp, DisplayHandler.Rotation );
    cvh = findobj( 'tag', 'RotationValue' );
    set( cvh, 'Label', rotation_string );

	delete( src );
end


% ============  Amplifier parameters menu ============

function ExcitationTableSelection_Callback(hObject, eventdata, handles)
	global DisplayHandler;
    
    if ( DLLGetAmpType( DisplayHandler.CurrentAmp ) == 400 )
       exd = dialog( 'Position', [300 300 400 100], 'Name', 'NoExcitationTable' );

        uicontrol( 'Parent',exd, 'Style','text', 'Position',[10  50 380 30], 'FontSize', 13, 'String', 'Accu-type platforms have no excitation settings' );
        uicontrol( 'Parent',exd, 'Position',[170 10 70 25], 'String','Close', 'Callback','delete(gcf)' );
        
       return; 
    end

    extable = DLLGetExcitationTable( DisplayHandler.CurrentAmp );
    
    table_line1 = string( sprintf( '%8.3f%8.3f%8.3f%8.3f%8.3f%8.3f', extable(:,1) ) );
    table_line2 = string( sprintf( '%8.3f%8.3f%8.3f%8.3f%8.3f%8.3f', extable(:,2) ) );
    table_line3 = string( sprintf( '%8.3f%8.3f%8.3f%8.3f%8.3f%8.3f', extable(:,3) ) );

    exd = dialog( 'Position',[300 300 400 230], 'Name','ExcitationTable' );
    
    uicontrol( 'Parent',exd, 'Style','text', 'Position',[10 170 380 30], 'FontSize', 13, 'String', ' Excitation table for currently selected amplifier :' );
    uicontrol( 'Parent',exd, 'Style','text', 'Position',[10 140 360 30], 'FontSize', 13, 'String', '    Fx        Fy        Fz        Mx       My       Mz ' );
    uicontrol( 'Parent',exd, 'Style','text', 'Position',[10 110 360 30], 'FontSize', 13, 'String', table_line1 );
    uicontrol( 'Parent',exd, 'Style','text', 'Position',[10  80 360 30], 'FontSize', 13, 'String', table_line2 );
    uicontrol( 'Parent',exd, 'Style','text', 'Position',[10  50 360 30], 'FontSize', 13, 'String', table_line3 );
    uicontrol( 'Parent',exd, 'Position',[170 10 70 25], 'String','Close', 'Callback','delete(gcf)' );

end

function GainTableSelection_Callback(hObject, eventdata, handles)
    global DisplayHandler;
    
    if ( DLLGetAmpType( DisplayHandler.CurrentAmp ) == 400 )
       exd = dialog( 'Position', [300 300 360 100], 'Name', 'NoGainTable' );

        uicontrol( 'Parent',exd, 'Style','text', 'Position',[10  50 340 30], 'FontSize', 13, 'String', 'Accu-type platforms have no gain settings' );
        uicontrol( 'Parent',exd, 'Position',[145 10 70 25], 'String','Close', 'Callback','delete(gcf)' );
        
       return; 
    end

    gaintable = DLLGetGainTable( DisplayHandler.CurrentAmp );
    
    table_line1 = string( sprintf( '%8.3f%8.3f%8.3f%8.3f%8.3f%8.3f', gaintable(:,1) ) );
    table_line2 = string( sprintf( '%8.3f%8.3f%8.3f%8.3f%8.3f%8.3f', gaintable(:,2) ) );
    table_line3 = string( sprintf( '%8.3f%8.3f%8.3f%8.3f%8.3f%8.3f', gaintable(:,3) ) );
    table_line4 = string( sprintf( '%8.3f%8.3f%8.3f%8.3f%8.3f%8.3f', gaintable(:,4) ) );

    exd = dialog( 'Position',[300 300 400 250], 'Name','GainTable' );
    
    uicontrol( 'Parent',exd, 'Style','text', 'Position',[10 200 360 30], 'FontSize', 13, 'String', '  Gain table for currently selected amplifier :' );
    uicontrol( 'Parent',exd, 'Style','text', 'Position',[10 170 360 30], 'FontSize', 13, 'String', '    Fx        Fy        Fz        Mx       My       Mz ' );
    uicontrol( 'Parent',exd, 'Style','text', 'Position',[10 140 360 30], 'FontSize', 13, 'String', table_line1 );
    uicontrol( 'Parent',exd, 'Style','text', 'Position',[10 110 360 30], 'FontSize', 13, 'String', table_line2 );
    uicontrol( 'Parent',exd, 'Style','text', 'Position',[10  80 360 30], 'FontSize', 13, 'String', table_line3 );
    uicontrol( 'Parent',exd, 'Style','text', 'Position',[10  50 360 30], 'FontSize', 13, 'String', table_line4 );
    uicontrol( 'Parent',exd, 'Position',[170 10 70 25], 'String','Close', 'Callback','delete(gcf)' );

end

