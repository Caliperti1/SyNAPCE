% ==============================================================================
%  AMTI Matlab Test Framework
% ==============================================================================
%  Copyright © 2017 Applied Mechanical Technology Incorporated
%
%  For private use of AMTI customers;  redistribution restricted.
% ==============================================================================


function DLLResetSoftware( amp_index )

	global DLLInterface;

	if ~isfield(DLLInterface, 'lib') || isempty(DLLInterface.lib) || ~libisloaded(DLLInterface.lib) || ~DLLInterface.Initialized
		return;
	end

    %  If there is no amp index as an argument, broadcast the reset to all amps
    if ( nargin == 0 )
        calllib(DLLInterface.lib, 'fmBroadcastResetSoftware');
        pause( 0.25 );
        return;
    end

    if ( amp_index < 1 || amp_index > 16 )
        return;
    end

    %  Select the requested amp
	calllib(DLLInterface.lib, 'fmDLLSelectDeviceIndex', amp_index-1);

	%  Send the reset command to the selected signal conditioner
	calllib(DLLInterface.lib, 'fmResetSoftware');
    
    pause( 0.25 );

end

