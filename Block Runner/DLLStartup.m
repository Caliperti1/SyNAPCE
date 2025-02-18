% ==============================================================================
%  AMTI Matlab Test Framework
% ==============================================================================
%  Copyright © 2017 Applied Mechanical Technology Incorporated
%
%  For private use of AMTI customers;  redistribution restricted.
% ==============================================================================


% ==============================================================================
%	DLLStartup
% ==============================================================================
%
%  Start running the DLL and find out what devices are active
%
function status = DLLStartup()

	global DLLInterface;

	if ~isfield(DLLInterface, 'lib') || isempty(DLLInterface.lib) || ~libisloaded(DLLInterface.lib)
		status = -1;
		return;
	end

	DLLInterface.Initialized = false;
	DLLInterface.DeviceCount = 0;
    DLLInterface.Running = false;

	%  Fire up the DLL
	calllib(DLLInterface.lib, 'fmDLLInit');

	timeout = 12.0 / (24*3600);		%  Clock time is measured in days, so convert from seconds
	start_time = now();
	end_time = start_time + timeout;

	%  Loop and wait for initialization to complete
	init_status = 0;
	loop_count = 0;
	while (init_status == 0) && (now() < end_time)
		init_status = calllib(DLLInterface.lib, 'fmDLLIsDeviceInitComplete');
		pause(.1);
		loop_count = loop_count + 1;
	end

	elapsed_time = (now() - start_time) * 24 * 3600;
	startup_message = sprintf('%.2f seconds, %d passes', elapsed_time, loop_count);

	switch init_status
		case 0
			fprintf(2, 'DLL initalization timed out\n');
            status = -1;
		case 1
			DLLInterface.Initialized = true;
			fprintf('DLL %d.%d initialized [%s] but no signal conditioners were found\n', DLLInterface.Version.Major, DLLInterface.Version.Minor, startup_message);
            status = 0;
		case 2
			DLLInterface.Initialized = true;
			DLLInterface.DeviceCount = calllib(DLLInterface.lib, 'fmDLLGetDeviceCount');
			fprintf('DLL %d.%d initialized [%s] with %d signal conditioners active\n', DLLInterface.Version.Major, DLLInterface.Version.Minor, startup_message, DLLInterface.DeviceCount);
            status = DLLInterface.DeviceCount;
        otherwise
			fprintf(2, 'Unexpected return value %d from fmDLLIsDeviceInitComplete\n', init_status);
            status = -1;
	end

    %  If we are properly initialized, set data collection parameters to some sensible defaults
    calllib(DLLInterface.lib, 'fmDLLSetUSBPacketSize', 512);        %  Standard packet size
    calllib(DLLInterface.lib, 'fmDLLSetDataFormat', 1);             %  8 items per dataset
    DLLInterface.ChannelCount = 8;
    calllib(DLLInterface.lib, 'fmDLLPostDataReadyMessages',0);      %  Polled data acquisition

    calllib(DLLInterface.lib, 'fmBroadcastStop');                   %  Stop just in case...

end

