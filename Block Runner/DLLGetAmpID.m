% ==============================================================================
%  AMTI Matlab Test Framework
% ==============================================================================
%  Copyright © 2017 Applied Mechanical Technology Incorporated
%
%  For private use of AMTI customers;  redistribution restricted.
% ==============================================================================


function [ ampmodel, ampID ] = DLLGetAmpID( amp_index )

	global DLLInterface;

	if ~isfield(DLLInterface, 'lib') || isempty(DLLInterface.lib) || ~libisloaded(DLLInterface.lib) || ~DLLInterface.Initialized
		return;
	end
    
    if ( amp_index < 1 || amp_index > 16 )
        return;
    end

    %  Select the requested amp
	calllib(DLLInterface.lib, 'fmDLLSelectDeviceIndex', amp_index-1);

    %  Get the amplifier model name from the DLL
    NameBuf = libpointer('int8Ptr',int8(zeros(1,32)));
	calllib(DLLInterface.lib, 'fmGetAmplifierModelNumber', NameBuf);
    rawArray = NameBuf.Value;
    i = find(rawArray==0);
    ampmodel = char(rawArray(1:i-1));
    
    %  Get the amplifier serial number from the DLL
	calllib(DLLInterface.lib, 'fmGetAmplifierSerialNumber', NameBuf);
    rawArray = NameBuf.Value;
    i = find(rawArray==0);
    ampID = char(rawArray(1:i-1));

end
