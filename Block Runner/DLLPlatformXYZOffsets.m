% ==============================================================================
%  AMTI Matlab Test Framework
% ==============================================================================
%  Copyright © 2017 Applied Mechanical Technology Incorporated
%
%  For private use of AMTI customers;  redistribution restricted.
% ==============================================================================


function offsets_output = DLLPlatformXYZOffsets( amp_index, offsets_input )

	global DLLInterface;

	if ~isfield(DLLInterface, 'lib') || isempty(DLLInterface.lib) || ~libisloaded(DLLInterface.lib) || ~DLLInterface.Initialized
		return;
	end
    
    if ( amp_index < 1 || amp_index > 16 )
        return;
    end

	valArray = libpointer('singlePtr', single(zeros(1,3)));

    %  Select the requested amp
	calllib(DLLInterface.lib, 'fmDLLSelectDeviceIndex', amp_index-1);

    if nargin == 2
        %  Send the requested offsets to the DLL for this amp
        valArray.Value = offsets_input;
        calllib(DLLInterface.lib, 'fmSetPlatformXYZOffsets', valArray);
    end
    
    calllib(DLLInterface.lib, 'fmGetPlatformXYZOffsets', valArray);
	offsets_output = valArray.Value;
end

