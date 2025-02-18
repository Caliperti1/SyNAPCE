% ==============================================================================
%  AMTI Matlab Test Framework
% ==============================================================================
%  Copyright © 2017 Applied Mechanical Technology Incorporated
%
%  For private use of AMTI customers;  redistribution restricted.
% ==============================================================================


function rate_output = DLLAcquisitionRate( rate_input )

	global DLLInterface;

	if ~isfield(DLLInterface, 'lib') || isempty(DLLInterface.lib) || ~libisloaded(DLLInterface.lib) || ~DLLInterface.Initialized
		return;
	end
    
    if nargin == 1

        %  Send the requested rate to the DLL
        calllib(DLLInterface.lib, 'fmBroadcastAcquisitionRate', rate_input);
        calllib(DLLInterface.lib, 'fmBroadcastResetSoftware');
        pause(.3)
    end
    
	rate_output = calllib(DLLInterface.lib, 'fmDLLGetAcquisitionRate');

end
