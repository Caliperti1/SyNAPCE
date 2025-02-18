% ==============================================================================
%  AMTI Matlab Test Framework
% ==============================================================================
%  Copyright © 2017 Applied Mechanical Technology Incorporated
%
%  For private use of AMTI customers;  redistribution restricted.
% ==============================================================================


function gains_output = DLLGains( amp_index, gains_input )

	global DLLInterface;

	if ~isfield(DLLInterface, 'lib') || isempty(DLLInterface.lib) || ~libisloaded(DLLInterface.lib) || ~DLLInterface.Initialized
		return;
	end
    
    if ( amp_index < 1 || amp_index > 16 )
        return;
    end

    %  Select the requested amp
	calllib(DLLInterface.lib, 'fmDLLSelectDeviceIndex', amp_index-1);

	valArray = libpointer('int32Ptr', single(zeros(1,6)));

    if ( nargin == 2 )
        %  Change Matlab indices to C indices
        gains_input = gains_input - 1;
        %  Set the gain settings in the DLL
        valArray.Value = gains_input;
        calllib(DLLInterface.lib, 'fmSetCurrentGains', valArray);
    end
    
    %  Get the gain settings from the DLL
	calllib(DLLInterface.lib, 'fmGetCurrentGains', valArray);
    gains_output = valArray.Value;
    %  Change C indices to Matlab indices
	gains_output = gains_output + 1;
    
end

