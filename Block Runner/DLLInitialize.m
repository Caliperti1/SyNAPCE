% ==============================================================================
%  AMTI Matlab Test Framework
% ==============================================================================
%  Copyright © 2017 Applied Mechanical Technology Incorporated
%
%  For private use of AMTI customers;  redistribution restricted.
% ==============================================================================


% ==============================================================================
%	DLLInitialize
% ==============================================================================
%
%  Initialization of the AMTI digital device DLL in the Matlab context
%
function status = DLLInitialize( control_sense )

    if ~control_sense
        CleanupDLL();
        return;
    end
    
	global DLLInterface

	%hfname = 'AMTIUSBDeviceDefinitions.h';
	dllfname = 'AMTIUSBDevice';
	protofname = [dllfname '_mproto'];

	mfil = mfilename();

	if isfield(DLLInterface, 'lib') && ~isempty(DLLInterface.lib)
		if libisloaded(DLLInterface.lib)
			fprintf('The %s DLL Version %d.%d appears to be loaded already\n', dllfname, DLLInterface.Version.Major, DLLInterface.Version.Minor);
            status = 1;
            return
		else
			%  Clean up any improper data and try to reload
			warning([mfil ':foundUnknownData'], ...
				'The DLLInterface.lib was improperly loaded - attempting reload');
			DLLInterface.lib = [];
			DLLInterface.lib_exit = [];
		end
	end

	%  See if the prototypes have been previously built
	if exist(protofname, 'file')
		loadlibrary(dllfname, str2func(protofname));
	end

	%  Mark the DLL as uninitialized, since it's just been loaded.
    DLLInterface.Initialized = false;

	%  Set up automatic cleanup of the DLL at exit
	if libisloaded(dllfname)
		DLLInterface.lib = dllfname;
		DLLInterface.lib_exit = onCleanup(@CleanupDLL);
        version = calllib(DLLInterface.lib, 'fmDLLGetVersionID');
        DLLInterface.Version.Major = floor(version / 10000);
        DLLInterface.Version.Minor = floor(mod(version, 10000) / 100);
        status = 1;
	else
		DLLInterface.lib = [];
        status = 0;
	end
end


% ==============================================================================
%	CleanupDLL
% ==============================================================================
%
%  Cleanup of the AMTI digital device DLL in the Matlab context
%
function CleanupDLL()

	global DLLInterface

	persistent norecurse
	if isempty(norecurse)
		norecurse = 0;
	end

	if norecurse > 0
		return;
	end

	norecurse = 1;

	if isfield(DLLInterface, 'lib') && ~isempty(DLLInterface.lib)
		if ischar(DLLInterface.lib) && libisloaded(DLLInterface.lib)
			if isfield(DLLInterface, 'Initialized') && DLLInterface.Initialized
				calllib(DLLInterface.lib, 'fmDLLShutDown');
				DLLInterface.Initialized = false;
				pause(.5);
			end
			unloadlibrary(DLLInterface.lib);
		end
		DLLInterface.lib = [];
	end

	if isfield(DLLInterface, 'lib_exit') && ~isempty(DLLInterface.lib_exit)
		DLLInterface.lib_exit = [];		% could spawn a recursive call
		DLLInterface = rmfield(DLLInterface, 'lib_exit'); 
	end

	norecurse = 0;
end

