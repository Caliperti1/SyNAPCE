% ==============================================================================
%  AMTI Matlab Test Framework
% ==============================================================================
%  Copyright © 2017 Applied Mechanical Technology Incorporated
%
%  For private use of AMTI customers;  redistribution restricted.
% ==============================================================================


function rotation_output = DLLPlatformRotation( amp_index, rotation_input )

	global DLLInterface;

	if ~isfield(DLLInterface, 'lib') || isempty(DLLInterface.lib) || ~libisloaded(DLLInterface.lib) || ~DLLInterface.Initialized
		return;
	end

    if ( amp_index < 1 || amp_index > 16 )
        return;
    end

    %  Select the requested amp
	calllib(DLLInterface.lib, 'fmDLLSelectDeviceIndex', amp_index-1);

    if nargin == 2
        %  Send the requested rotation to the DLL for this amp
        rotation_sent = float_hacker( rotation_input );
        calllib(DLLInterface.lib, 'fmSetPlatformRotation', rotation_sent);
    end
    
    lt = calllib(DLLInterface.lib, 'fmGetPlatformRotation');
	rotation_output = single( lt );
end

%
%  This function hacks up a single-precision floating point number so that
%  its 4 bytes appear as the low-order half of a double-precision value
%
%  This appears to be necessary to make MatLab talk to Visual C++
%
function hacked_float = float_hacker( invalue )
    single_value = single( invalue );
    hexstr = num2hex( single_value );
    extended_hexstr = [ '40000000', hexstr ];
    hacked_float = hex2num( extended_hexstr );
end

