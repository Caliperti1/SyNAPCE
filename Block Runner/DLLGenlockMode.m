% ==============================================================================
%  AMTI Matlab Test Framework
% ==============================================================================
%  Copyright © 2017 Applied Mechanical Technology Incorporated
%
%  For private use of AMTI customers;  redistribution restricted.
% ==============================================================================


function mode_output = DLLGenlockMode( mode_input )

	global DLLInterface;

	if ~isfield(DLLInterface, 'lib') || isempty(DLLInterface.lib) || ~libisloaded(DLLInterface.lib) || ~DLLInterface.Initialized
		return;
	end
    
    if ( nargin == 1 )
        %  If the mode is legal, send it to the DLL
        if mode_input >= 1 && mode_input <= 3
            calllib(DLLInterface.lib, 'fmBroadcastGenlock', mode_input-1);
            calllib(DLLInterface.lib, 'fmBroadcastResetSoftware');
            pause(.3)
        end
    end
      
	%  Return the current genlock mode
    mode_output = calllib(DLLInterface.lib, 'fmDLLGetGenlock') + 1;

end
