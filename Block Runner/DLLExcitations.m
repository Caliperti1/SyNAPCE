% ==============================================================================
%  AMTI Matlab Test Framework
% ==============================================================================
%  Copyright © 2017 Applied Mechanical Technology Incorporated
%
%  For private use of AMTI customers;  redistribution restricted.
% ==============================================================================


function excitations_output = DLLExcitations( amp_index, excitations_input )

	global DLLInterface;

	if ~isfield(DLLInterface, 'lib') || isempty(DLLInterface.lib) || ~libisloaded(DLLInterface.lib) || ~DLLInterface.Initialized
		return;
	end
    
    if ( amp_index < 1 || amp_index > 16 )
        return;
    end

    %  Select the requested amp
	calllib(DLLInterface.lib, 'fmDLLSelectDeviceIndex', amp_index-1);

	valArray = libpointer('int32Ptr', single(zeros(1,6)));

    if ( nargin == 2 )
        %  Change Matlab indices to C indices
        excitations_input = excitations_input - 1;
        %  Set the excitation settings in the DLL
        valArray.Value = excitations_input;
        calllib(DLLInterface.lib, 'fmSetCurrentExcitations', valArray);
    end
    
    %  Get the excitation settings from the DLL
	calllib(DLLInterface.lib, 'fmGetCurrentExcitations', valArray);
    excitations_output = valArray.Value;
    %  Change C indices to Matlab indices
	excitations_output = excitations_output + 1;
    
end


