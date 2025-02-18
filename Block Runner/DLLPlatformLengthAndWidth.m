% ==============================================================================
%  AMTI Matlab Test Framework
% ==============================================================================
%  Copyright © 2017 Applied Mechanical Technology Incorporated
%
%  For private use of AMTI customers;  redistribution restricted.
% ==============================================================================


function dimensions_output = DLLPlatformLengthAndWidth( amp_index, dimensions_input )

	global DLLInterface;

	if ~isfield(DLLInterface, 'lib') || isempty(DLLInterface.lib) || ~libisloaded(DLLInterface.lib) || ~DLLInterface.Initialized
		return;
	end
    
    if ( amp_index < 1 || amp_index > 16 )
        return;
    end

    XdimBuf = libpointer('int8Ptr',int8(zeros(1,20)));
    YdimBuf = libpointer('int8Ptr',int8(zeros(1,20)));

    %  Select the requested amp
	calllib(DLLInterface.lib, 'fmDLLSelectDeviceIndex', amp_index-1);

    if nargin == 2
        %  Send the requested dimensions to the DLL for this amp
        xstr = int8( sprintf( '%5.2f', dimensions_input(1) ) );
        xlen = length( xstr );
        xstr(xlen:20)= 0;
        XdimBuf.Value = xstr;
        ystr = int8( sprintf( '%5.2f', dimensions_input(2) ) );
        ylen = length( ystr );
        ystr(ylen:20)= 0;
        YdimBuf.Value = ystr;
        calllib(DLLInterface.lib, 'fmSetPlatformLengthAndWidth', XdimBuf, YdimBuf);
    end
    
	calllib(DLLInterface.lib, 'fmGetPlatformLengthAndWidth', XdimBuf, YdimBuf);
    rawArray = XdimBuf.Value;
    i = find(rawArray==0);
    xstr = char(rawArray(1:i-1));
    dimensions_output(1) = str2double( xstr );
    
    rawArray = YdimBuf.Value;
    i = find(rawArray==0);
    ystr = char(rawArray(1:i-1));
    dimensions_output(2) = str2double( ystr );

end

