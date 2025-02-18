% ==============================================================================
%  AMTI Matlab Test Framework
% ==============================================================================
%  Copyright © 2017 Applied Mechanical Technology Incorporated
%
%  For private use of AMTI customers;  redistribution restricted.
% ==============================================================================


function DLLCollecting( state )

	global DLLInterface;

	if ~isfield(DLLInterface, 'lib') || isempty(DLLInterface.lib) || ~libisloaded(DLLInterface.lib) || ~DLLInterface.Initialized
		return;
	end
    
    if state && DLLInterface.Running
		fprintf('Data collection is already started');
        return
    end
    
    if ~state && ~DLLInterface.Running
		fprintf('Data collection is not active');
        return
    end
    
    if state
        calllib( DLLInterface.lib, 'fmBroadcastStart' );
        DLLInterface.Running = true;
    else
        calllib( DLLInterface.lib, 'fmBroadcastStop' );
        pause( 0.5 );
        DLLInterface.Running = false;
    end
    
end
