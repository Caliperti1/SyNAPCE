% ==============================================================================
%  AMTI Matlab Test Framework
% ==============================================================================
%  Copyright © 2017 Applied Mechanical Technology Incorporated
%
%  For private use of AMTI customers;  redistribution restricted.
% ==============================================================================


function DLLSetPacketSize( size )

	global DLLInterface;

	if ~isfield(DLLInterface, 'lib') || isempty(DLLInterface.lib) || ~libisloaded(DLLInterface.lib) || ~DLLInterface.Initialized
		return;
	end

    if size == 6
        calllib(DLLInterface.lib, 'fmDLLSetDataFormat', 0);
        DLLInterface.ChannelCount = 6;
    end
    
    if size == 8
        calllib(DLLInterface.lib, 'fmDLLSetDataFormat', 1);
        DLLInterface.ChannelCount = 8;
    end
    
end
