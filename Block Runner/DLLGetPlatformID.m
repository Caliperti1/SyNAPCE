% ==============================================================================
%  AMTI Matlab Test Framework
% ==============================================================================
%  Copyright © 2017 Applied Mechanical Technology Incorporated
%
%  For private use of AMTI customers;  redistribution restricted.
% ==============================================================================


function [ plattype, platID ] = DLLGetPlatformID( amp_index )

	global DLLInterface;

	if ~isfield(DLLInterface, 'lib') || isempty(DLLInterface.lib) || ~libisloaded(DLLInterface.lib) || ~DLLInterface.Initialized
		return;
	end
    
    if ( amp_index < 1 || amp_index > 16 )
        return;
    end

    %  Select the requested amp
	calllib(DLLInterface.lib, 'fmDLLSelectDeviceIndex', amp_index-1);

    %  Get the platform model name from the DLL
    NameBuf = libpointer('int8Ptr',int8(zeros(1,32)));
	calllib(DLLInterface.lib, 'fmGetPlatformModelNumber', NameBuf);
    rawArray = NameBuf.Value;
    i = find(rawArray==0);
    plattype = char(rawArray(1:i-1));
    
    %  Get the platform serial number from the DLL
	calllib(DLLInterface.lib, 'fmGetPlatformSerialNumber', NameBuf);
    rawArray = NameBuf.Value;
    i = find(rawArray==0);
    platID = char( rawArray(1:i-1) );

end
