% ==============================================================================
%  AMTI Matlab Test Framework
% ==============================================================================
%  Copyright © 2017 Applied Mechanical Technology Incorporated
%
%  For private use of AMTI customers;  redistribution restricted.
% ==============================================================================


function DLLAcquisition(~,~,~)

	global DLLInterface;
    
	if ~isfield(DLLInterface, 'lib') || isempty(DLLInterface.lib) || ~libisloaded(DLLInterface.lib) || ~DLLInterface.Initialized
		return;
	end
    
    if ~DLLInterface.Running
        return
    end

    persistent dataArray;
    persistent dataArraySize;

    %  The data size is the number of bytes to be returned by the DLL
    dataSize = DLLInterface.DeviceCount * DLLInterface.ChannelCount * 16 * 4;
    
    %  Allocate data the very first time this routine is called
    if isempty(dataArray)
        %  A pointer to an array of floats
        dataArray = libpointer('singlePtr', single(zeros(1,dataSize)));
        dataArraySize = dataSize;
    end
    
    %  We also need to reallocate in case the data packet size has changed
    if dataSize ~= dataArraySize
        %  A pointer to an array of floats
        fprintf( 'Reallocating buffer from %d to %d bytes\n', dataArraySize, dataSize );
        dataArray = libpointer('singlePtr', single(zeros(1,dataSize)));
        dataArraySize = dataSize;
    end

    ret = 1;
    while (ret > 0)
        %  Call the DLL to acquire data
        ret = calllib( DLLInterface.lib, 'fmDLLGetTheFloatDataLBVStyle', dataArray, dataSize );
        
        if( ret > 0 )
            %  We have data, so invoke the colleciton callback to handle it
            rawdata = dataArray.Value;
            DataCollectionCallback( rawdata, dataSize ); 
        end
    end
    
end