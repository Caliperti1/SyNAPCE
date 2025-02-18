% ==============================================================================
%  AMTI Matlab Test Framework
% ==============================================================================
%  Copyright © 2017 Applied Mechanical Technology Incorporated
%
%  For private use of AMTI customers;  redistribution restricted.
% ==============================================================================

function DataCollectionCallback( dataArray, ~ )

	global DataHandler;
    
    if ~DataHandler.Initialized
        return;
    end
    
    % -------------------------------------------------------------------------------------------------
    %  User function: handle a single data packet returned from the AMTI data collection DLL
    %
    %  There are 16 datasets for each active amplifier/forceplate combination, each with 8 channels
    %
    %  This is a model function and should be replaced by whatever collection or analysis code
    %  is appropriate for your project
    % -------------------------------------------------------------------------------------------------
    
    DataHandler.CallbackCount = DataHandler.CallbackCount + 1;
    
    newIndex = dataArray(1);
    if ( newIndex ~= DataHandler.LastIndex + 16 )
    %    if ( DataHandler.LastIndex == 0 && newIndex == 1 )
    %        fprintf( 'Starting live data flow\n' );
    %    else
    %        fprintf( 'Error in index: %d expected, %d seen\n', DataHandler.LastIndex + 16, newIndex );
    %    end        
    end
    DataHandler.LastIndex = newIndex;
    
    %  Record a single point of the selected amplifier/plate
    DataHandler.Sample = dataArray( DataHandler.AmpOffset+2 : DataHandler.AmpOffset+7 );
    
    %  Calculate COP if there's sufficient force applied to the plate
    if ( DataHandler.Sample(3) > DataHandler.FzCutoff )
        DataHandler.COP.X = -DataHandler.Sample(5) / DataHandler.Sample(3);
        DataHandler.COP.Y =  DataHandler.Sample(4) / DataHandler.Sample(3);

    end

    DataHandler.PacketCount = DataHandler.PacketCount + 16;

    %  If no channels are active, we have nothing to store in the buffer
	if ( DataHandler.ActiveChannels == 0 )
        return;
	end
    
    %  Copy the dataset to the circle buffer
	DataHandler.Buffer( DataHandler.DataPointer : DataHandler.DataPointer+(DataHandler.DataLength-1) ) = dataArray( DataHandler.DataMask );

	%  Update the buffer pointer
    DataHandler.DataCount   = DataHandler.DataCount   + DataHandler.DataLength;
    DataHandler.DataPointer = DataHandler.DataPointer + DataHandler.DataLength;
    if ( DataHandler.DataPointer >= DataHandler.BufferSize )
        %  Return to the top of the circle buffer
        DataHandler.DataPointer = 1;
    end
    
end
