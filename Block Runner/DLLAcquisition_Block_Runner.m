% ==============================================================================
%  AMTI Matlab Test Framework
% ==============================================================================
%  Copyright © 2017 Applied Mechanical Technology Incorporated
%
%  For private use of AMTI customers;  redistribution restricted.
% ==============================================================================
%  Adapted for a Matlab/forceplate driven video game by Caspian Bell, J. Josiah Steckenrider
%  United States Military Academy
%  West Point, NY

function DLLAcquisition_Block_Runner(~,~,~)
 
    global DLLInterface;
    global COP COPp;
    global DataHandler;
    global r_wbs vfwd N arena_w harena f angle_wbs w corners_b stance pen lossfactor hBlocks2D sensitivity acc dist path condition sortv len wid mN rN lN COPx COPy T Note penalty vidObj secn Ypos;
 
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
            assignin('base','COP',COP)
            %assignin(['base','COPp',COPp])
            COPp = COP;
            COP = [-DataHandler.COP.X DataHandler.COP.Y];
        end
    end
    
    acc = acc + 1;
    dist = dist + vfwd;
    pos = sensitivity*COP;
    path(acc,:) = [pos(1)+5 dist];
    
    %Creates array for post processing of metrics
     COPx(acc)=COP(1); %Records x-position of the COP
     COPy(acc)=COP(2); %Records y-position of the COP
     T(acc)=toc; %Records time of the data point
     Ypos(acc)=len-arena_w(2,3);

    % Move blocks and arena forward by amount v and moving blocks laterally
    % by Vblk
    r_wbs  = r_wbs - repmat([0 ; vfwd ; 0],1,N);
    r_wbs = r_wbs+[sortv;zeros(1,N);zeros(1,N)];
    arena_w = arena_w - [0 0 0 0 ; 0 0 vfwd vfwd ; 0 0 0 0];
    for i= 1:mN % Flips the direction of block when it reaches the edge of the arena
        if r_wbs(1,lN+i)>=wid | r_wbs(1,lN+i)<=0
            sortv(lN+i)=-sortv(lN+i);
        end
    end
    % Change camera location
    r_wc = [5+pos(1) ; 0 ; 2];
    
    % % Define orientation of camera
    yaw_c = 0; % Rotates camera about z
    pitch_c = 0; % Rotates camera about y
    roll_c = 0; % Rotates camera about x
 
    % Generate rotation matrix from camera to world frame
    R_cwz = [cos(-yaw_c) -sin(-yaw_c) 0 ; sin(-yaw_c) cos(-yaw_c) 0 ; 0 0 1];
    R_cwy = [cos(-pitch_c) 0 sin(-pitch_c) ; 0 1 0 ; -sin(-pitch_c) 0 cos(-pitch_c)];
    R_cwx = [1 0 0 ; 0 cos(-roll_c) -sin(-roll_c) ; 0 sin(-roll_c) cos(-roll_c)];
    R_cw = R_cwz*R_cwy*R_cwx;
    
    % Transform location of arena to camera frame
    arena_c = R_cw*(arena_w-repmat(r_wc,1,4));
    
    % Check if game is over (i.e. far end of arena has passed the camera)
    if arena_w(2,3) < 0
        condition = false;
        text(-0.8,-0.1,'Press any key to end the program','Color','green','FontSize',14)
        DLLCollecting(false);
    end
    
    % Replace vertices behind the camera with small nonzero values (0.01)
    signcheck = (sign(arena_c(2,:)) + 1)/2;
    signcheck = [ones(1,4) ; signcheck ; ones(1,4)];
    arena_c = arena_c.*signcheck;
    arena_c(arena_c == 0) = 0.01;
    
    c1 = f*[(arena_c(1,1)/arena_c(2,1)) ; (arena_c(3,1)/arena_c(2,1))];
    c2 = f*[(arena_c(1,2)/arena_c(2,2)) ; (arena_c(3,2)/arena_c(2,2))];
    c3 = f*[(arena_c(1,3)/arena_c(2,3)) ; (arena_c(3,3)/arena_c(2,3))];
    c4 = f*[(arena_c(1,4)/arena_c(2,4)) ; (arena_c(3,4)/arena_c(2,4))];
 
    Xarena = [c1(1) c2(1) c3(1) c4(1) c1(1)];
    Yarena = [c1(2) c2(2) c3(2) c4(2) c1(2)];
    set(harena,'xdata',Xarena,'ydata',Yarena)
    
    % Iterate through all blocks
    Blocks_c = cell(1,N);
    Blocks_w = cell(1,N);
    inRects = zeros(1,N);
    for i = 1:N
        % Transform location of blocks to world and camera frames
        r_wb = r_wbs(:,i);
        
        angle_wbs(:,i) = angle_wbs(:,i) + [w ; 0 ; 0];
        yaw_b = angle_wbs(1,i);
        pitch_b = angle_wbs(2,i);
        roll_b = angle_wbs(3,i);
        R_wbz = [cos(yaw_b) -sin(yaw_b) 0 ; sin(yaw_b) cos(yaw_b) 0 ; 0 0 1];
        R_wby = [cos(pitch_b) 0 sin(pitch_b) ; 0 1 0 ; -sin(pitch_b) 0 cos(pitch_b)];
        R_wbx = [1 0 0 ; 0 cos(roll_b) -sin(roll_b) ; 0 sin(roll_b) cos(roll_b)];
        R_wb = R_wbz*R_wby*R_wbx;
        corners_w = r_wb + R_wb*corners_b;
        corners_c = R_cw*(corners_w-repmat(r_wc,1,8));
        
        % Check if camera's projected position on the floor overlaps any
        % blocks
        camera = r_wc(1:2)-[stance/2 ; 0];
        block = r_wb(1:2);
        angle = yaw_b;
        x = camera - block;
        R = [cos(-angle) -sin(-angle) ; sin(-angle) cos(-angle)];
        xRot = R*x;
        if xRot(1) > -1/2 && xRot(1) < 1/2 && xRot(2) > -1/2 && xRot(2) < 1/2
            inRect1 = true;
        else
            inRect1 = false;
        end
        camera = r_wc(1:2)+[stance/2 ; 0];
        x = camera - block;
        R = [cos(-angle) -sin(-angle) ; sin(-angle) cos(-angle)];
        xRot = R*x;
        if xRot(1) > -1/2 && xRot(1) < 1/2 && xRot(2) > -1/2 && xRot(2) < 1/2
            inRect2 = true;
        else
            inRect2 = false;
        end
        inRects(i) = inRect1 || inRect2;
        
        % Replace vertices behind the camera with zeros
        signcheck = (sign(corners_c(2,:)) + 1)/2;
        signcheck = [ones(1,8) ; signcheck ; ones(1,8)];
        corners_c = corners_c.*signcheck;
        corners_c(corners_c == 0) = 0.01;
        Blocks_c{i} = corners_c;
        Blocks_w{i} = corners_w;
    end
    
    % Change plot color if collided with blocks
    if any(inRects)
        plotColor = 'red';
        penalty(acc)=1;
    else
        plotColor = 'black';
        penalty(acc)=0;
    end
    
    % Penalize leaving the arena
    if r_wc(1) < arena_w(1,1) || r_wc(1) > arena_w(1,2)
        plotColor = 'red';
        penalty(acc)=1;
    end
    
%Replots blocks in thier new positions
     for i = 1:length(Blocks_c)
        corners = Blocks_c{i};
        fighandle = hBlocks2D(i);
        if mean(corners(2,:)) < 50 && mean(corners(2,:)) > 0.01
            c1 = f*[(corners(1,1)/corners(2,1)) ; (corners(3,1)/corners(2,1))];
            c2 = f*[(corners(1,2)/corners(2,2)) ; (corners(3,2)/corners(2,2))];
            c3 = f*[(corners(1,3)/corners(2,3)) ; (corners(3,3)/corners(2,3))];
            c4 = f*[(corners(1,4)/corners(2,4)) ; (corners(3,4)/corners(2,4))];
            c5 = f*[(corners(1,5)/corners(2,5)) ; (corners(3,5)/corners(2,5))];
            c6 = f*[(corners(1,6)/corners(2,6)) ; (corners(3,6)/corners(2,6))];
            c7 = f*[(corners(1,7)/corners(2,7)) ; (corners(3,7)/corners(2,7))];
            c8 = f*[(corners(1,8)/corners(2,8)) ; (corners(3,8)/corners(2,8))];
 
            Xblock = [c1(1) c2(1) c4(1) c3(1) c1(1) c5(1) c6(1) c8(1) c7(1) c5(1) c6(1) c2(1) c4(1) c8(1) c7(1) c3(1)];
            Yblock = [c1(2) c2(2) c4(2) c3(2) c1(2) c5(2) c6(2) c8(2) c7(2) c5(2) c6(2) c2(2) c4(2) c8(2) c7(2) c3(2)];
            set(fighandle,'xdata',Xblock,'ydata',Yblock,'color',plotColor)
        end
    end
    
 
end

