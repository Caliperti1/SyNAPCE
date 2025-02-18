%% Block Runner - A Matlab FPV Video Game (Keyboard Controls)
% Josiah Steckenrider

% Clear workspace
clear all
close all
clc

notes=[];
n='null';

% Define translational and rotational "velocities"
vfwdbase = 0.4; % Translational forward
vfwd = vfwdbase;
if vfwd < vfwdbase
    vfwd = vfwdbase;
end
vss = 0.3; % Translational side-to-side
w = 0.1; % Rotational

% Define camera focal length
f = 1; % Focal length

% Define width between feet
stance = 0;

% Initialize health level and loss factor
health = 100;
lossfactor = 4;

% Determine whether or not to plot in 3D (slows things down a little)
plot3D = false; % Boolean

% Get screen size
screen = get(0,'screensize');

% Define block corners in block reference frame
corners_b = [-0.5 -0.5 -0.5 -0.5 0.5 0.5 0.5 0.5 ; ...
             -0.5 -0.5 0.5 0.5 -0.5 -0.5 0.5 0.5 ; ...
             0 1 0 1 0 1 0 1]; % Origin is at bottom center of block

% Define arena boundaries
r_wa = [0 ; 0.1 ; 0]; % Vector to the back-left corner of the arena
width = 10; % Width of arena
length = 10*width; % Length of arena
arena_w = repmat(r_wa,1,4) + ...
    [0 width width 0 ; 0 0 length length ; 0 0 0 0]; % 4 corners of arena

% Define location of camera in world frame
r_wc = [5 ; 0 ; 2]; % Vector from world origin to camera position

% Define orientation of camera
yaw_c = 0; % Rotates camera about z
pitch_c = 0; % Rotates camera about y
roll_c = 0; % Rotates camera about x

% Generate rotation matrix from camera to world frame
R_cwz = [cos(-yaw_c) -sin(-yaw_c) 0 ; sin(-yaw_c) cos(-yaw_c) 0 ; 0 0 1];
R_cwy = [cos(-pitch_c) 0 sin(-pitch_c) ; 0 1 0 ; -sin(-pitch_c) 0 cos(-pitch_c)];
R_cwx = [1 0 0 ; 0 cos(-roll_c) -sin(-roll_c) ; 0 sin(-roll_c) cos(-roll_c)];
R_cw = R_cwz*R_cwy*R_cwx;

% Transform arena corners into camera frame
arena_c = R_cw*(arena_w-repmat(r_wc,1,4));

% Randomly generate blocks
N = 100; % Number of blocks
blockxs = min(arena_w(1,:)) + width*rand(1,N); % Random x-coordinates of blocks
blockys = min(arena_w(2,:)) + length*rand(1,N); % Random y-coordinates of blocks
blockzs = zeros(1,N);  % All blocks are positioned on the "floor"
r_wbs = [blockxs ; blockys ; blockzs]; % Stack all world-to-block position vectors
angle_wbs = [2*pi*rand(1,N) ; zeros(1,N) ; zeros(1,N)]; % Randomly generate block orientations

% Set up 3D plot if requested
if plot3D
    figure(2)
    hold on
    harena3D = plot3([arena_w(1,1) arena_w(1,2) arena_w(1,3) arena_w(1,4) arena_w(1,1)], ...
        [arena_w(2,1) arena_w(2,2) arena_w(2,3) arena_w(2,4) arena_w(2,1)], ...
        [arena_w(3,1) arena_w(3,2) arena_w(3,3) arena_w(3,4) arena_w(3,1)], ...
        'color','magenta','linewidth',1.5); % Plot arena in 3D
    [~,~,~] = plotOrigin([0 0 0],[0 0 0],2,2,1.5); % Plot world origin
    [~,~,~] = plotOrigin(r_wc,[yaw_c pitch_c roll_c],2,2,1.5); % Plot camera origin
    hleftfoot = scatter3(r_wc(1)-stance/2,0,0,'filled','blue');
    hrightfoot = scatter3(r_wc(1)+stance/2,0,0,'filled','blue');
    axis equal % Make scaling correct
    ylim([min(arena_w(2,:))-0.2*width 30]) % Set limits on how much arena shows
    view([-35 40]) % Set camera viewing angle
%     view([0 90])
    set(gcf,'units','normalized','outerposition',[0 0 0.5 1]) % Move figure window to left half
end

% Set up 2D plot
hfig = figure(1);
set(hfig,'KeyPressFcn',@(h_obj,evt) assignin('base','xcam',evt.Key));
hold on
if plot3D % Decide where to put the figure window
    set(hfig,'units','normalized','outerposition',[0.5 0 0.5 1])
else
    if min(screen(3:4)) < 720
        set(hfig,'units','normalized','outerposition',[0 0 2 2])
    else
        set(gcf,'units','normalized','outerposition',[0 0 1 1])
%         set(hfig,'position',[0 0 720 720])
        movegui(hfig,'center')
    end
end
axis equal % Make scaling correct
xlim([-1 1]) % Set x limits from -1 to 1
ylim([-1 1]) % Set y limits from -1 to 1

% Plot arena corners in 2D image
c1 = f*[(arena_c(1,1)/arena_c(2,1)) ; (arena_c(3,1)/arena_c(2,1))];
c2 = f*[(arena_c(1,2)/arena_c(2,2)) ; (arena_c(3,2)/arena_c(2,2))];
c3 = f*[(arena_c(1,3)/arena_c(2,3)) ; (arena_c(3,3)/arena_c(2,3))];
c4 = f*[(arena_c(1,4)/arena_c(2,4)) ; (arena_c(3,4)/arena_c(2,4))];
figure(1)
Xarena = [c1(1) c2(1) c3(1) c4(1) c1(1)];
Yarena = [c1(2) c2(2) c3(2) c4(2) c1(2)];
harena = line(Xarena,Yarena,'color','magenta','linewidth',1.5);

% Plot initial health bar
hhealth = line([0.8-0.006*health 0.8],[0.8 0.8],'color','red','linewidth',3);
thealth = text(0.70,0.85,'100%','FontSize',8);
drawnow

% Transform location of blocks to world and camera frames and plot   
Blocks_c = cell(1,N); % Initialize cell array to store block corners in camera frame
for i = 1:N
    % For each block, determine location of corners in camera frame
    r_wb = r_wbs(:,i); % Extract vector from world origin to ith block origin
    yaw_b = angle_wbs(1,i); % Extract ith yaw
    pitch_b = angle_wbs(2,i); % Extract ith pitch
    roll_b = angle_wbs(3,i); % Extract ith roll
    R_wbz = [cos(yaw_b) -sin(yaw_b) 0 ; sin(yaw_b) cos(yaw_b) 0 ; 0 0 1];
    R_wby = [cos(pitch_b) 0 sin(pitch_b) ; 0 1 0 ; -sin(pitch_b) 0 cos(pitch_b)];
    R_wbx = [1 0 0 ; 0 cos(roll_b) -sin(roll_b) ; 0 sin(roll_b) cos(roll_b)];
    R_wb = R_wbz*R_wby*R_wbx; % Compute 3D rotation matrix for ith block
    corners_w = r_wb + R_wb*corners_b; % Transform ith block's corners into the world frame
    corners_c = R_cw*(corners_w-repmat(r_wc,1,8)); % Transform ith block's corners into camera frame
    
    % Replace vertices behind the camera with small nonzero values (0.01)
    signcheck = (sign(corners_c(2,:)) + 1)/2;
    signcheck = [ones(1,8) ; signcheck ; ones(1,8)];
    corners_c = corners_c.*signcheck;
    corners_c(corners_c == 0) = 0.01;
    Blocks_c{i} = corners_c;
    
    % Project 3D corners onto 2D plane
    c1 = f*[(corners_c(1,1)/corners_c(2,1)) ; (corners_c(3,1)/corners_c(2,1))];
    c2 = f*[(corners_c(1,2)/corners_c(2,2)) ; (corners_c(3,2)/corners_c(2,2))];
    c3 = f*[(corners_c(1,3)/corners_c(2,3)) ; (corners_c(3,3)/corners_c(2,3))];
    c4 = f*[(corners_c(1,4)/corners_c(2,4)) ; (corners_c(3,4)/corners_c(2,4))];
    c5 = f*[(corners_c(1,5)/corners_c(2,5)) ; (corners_c(3,5)/corners_c(2,5))];
    c6 = f*[(corners_c(1,6)/corners_c(2,6)) ; (corners_c(3,6)/corners_c(2,6))];
    c7 = f*[(corners_c(1,7)/corners_c(2,7)) ; (corners_c(3,7)/corners_c(2,7))];
    c8 = f*[(corners_c(1,8)/corners_c(2,8)) ; (corners_c(3,8)/corners_c(2,8))];
    
    % Stack all 8 corners' X and Y coordinates into vectors and plot
    Xblock = [c1(1) c2(1) c4(1) c3(1) c1(1) c5(1) c6(1) c8(1) c7(1) c5(1) c6(1) c2(1) c4(1) c8(1) c7(1) c3(1)];
    Yblock = [c1(2) c2(2) c4(2) c3(2) c1(2) c5(2) c6(2) c8(2) c7(2) c5(2) c6(2) c2(2) c4(2) c8(2) c7(2) c3(2)];
    hblock2D = line(Xblock,Yblock,'color','black','linewidth',1.5);
    
    % Add plot handle to array for in-the-loop plot updating
    hBlocks2D(i) = hblock2D;
    
    % Generate 3D plot of blocks if desired
    if plot3D
        Xblock = [corners_w(1,1) corners_w(1,2) corners_w(1,4) corners_w(1,3) corners_w(1,1) corners_w(1,5) corners_w(1,6) corners_w(1,8) corners_w(1,7) corners_w(1,5) corners_w(1,6) corners_w(1,2) corners_w(1,4) corners_w(1,8) corners_w(1,7) corners_w(1,3)];
        Yblock = [corners_w(2,1) corners_w(2,2) corners_w(2,4) corners_w(2,3) corners_w(2,1) corners_w(2,5) corners_w(2,6) corners_w(2,8) corners_w(2,7) corners_w(2,5) corners_w(2,6) corners_w(2,2) corners_w(2,4) corners_w(2,8) corners_w(2,7) corners_w(2,3)];
        Zblock = [corners_w(3,1) corners_w(3,2) corners_w(3,4) corners_w(3,3) corners_w(3,1) corners_w(3,5) corners_w(3,6) corners_w(3,8) corners_w(3,7) corners_w(3,5) corners_w(3,6) corners_w(3,2) corners_w(3,4) corners_w(3,8) corners_w(3,7) corners_w(3,3)];
        figure(2)
        hblock3D = plot3(Xblock,Yblock,Zblock,'black','linewidth',1.5);
        hBlocks3D(i) = hblock3D;
    end
end

% Intro to game
figure(1)
ht1 = text(-0.6,0.65,'BLOCK RUNNER','Color','green','FontSize',28);
ht2 = text(-0.6,0.5,'Avoid the blocks','Color','black','FontSize',14);
ht3 = text(-0.6,0.4,'Stay inside the arena','Color','black','FontSize',14);
ht4 = text(-0.6,0.3,'Side-to-side: left and right arrow keys','Color','black','FontSize',14);
ht5 = text(-0.6,0.2,'Stop drifting: up arrow key','Color','black','FontSize',14);
ht6 = text(-0.6,0.1,'Press any key to start','Color','black','FontSize',14);
waitforbuttonpress
delete(ht1)
delete(ht2)
delete(ht3)
delete(ht4)
delete(ht5)
delete(ht6)

% vidObj = VideoWriter('Block_Runner_Demo'); % Create a video object to write frames to
% vidObj.FrameRate = 24; % Specify the frame rate of the video
% vidObj.Quality = 100; % Specify the quality (resolution) of the video (100 is best)
% open(vidObj) % Open the video for writing

% Initialize accumulator and condition variables
acc = 1;
condition = true;
while condition    
    % Move block and arena forward by amount v
    r_wbs  = r_wbs - repmat([0 ; vfwd ; 0],1,N);
    arena_w = arena_w - [0 0 0 0 ; 0 0 vfwd vfwd ; 0 0 0 0];
    
    % Controls
    figure(1)
    if exist('xcam','var')
        switch xcam
            case 'leftarrow'
                r_wc = r_wc - [vss ; 0 ; 0];
                xcam = 'null';
%                 clear xcam % Comment out for control mode 1
            case 'rightarrow'
                r_wc = r_wc + [vss ; 0 ; 0];
                xcam = 'null';
%                 clear xcam % Comment out for control mode 1
            case 'uparrow'
%                 v = v + 0.1; % Comment for control mode 1
%                 xcam = 'null';
%                 clear xcam % Comment out for control mode 1
            case 'downarrow'
%                 v = v - 0.1; % Comment out for control mode 1
%                 xcam = 'null';
%                 clear xcam % Comment out for control mode 1
            case 'escape'
                condition = false;
                close(figure(1))
                break
        end
    end
    
    % Define orientation of camera
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
        figure(1)
        text(-0.8,0,'CONGRATS! YOU WON THE GAME!','Color','green','FontSize',18)
    end
    

        



        switch n
            case '1'
                notes(acc)=1;
            case '2'
                notes(acc)=2;
            case '3'
                notes(acc)=3;
            case '4'
                notes(acc)=4;
            case '5'
                notes(acc)=5;
            otherwise
                notes(acc)=0;
        end

    n='null';



    % Replace vertices behind the camera with small nonzero values (0.01)
    signcheck = (sign(arena_c(2,:)) + 1)/2;
    signcheck = [ones(1,4) ; signcheck ; ones(1,4)];
    arena_c = arena_c.*signcheck;
    arena_c(arena_c == 0) = 0.01;
    
    % Project arena boundary onto camera array
    project3Dto2DArena(arena_c,f,harena)
    
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
        inRect1 = isInRect(r_wc(1:2)-[stance/2 ; 0],r_wb(1:2),yaw_b,1,1);
        inRect2 = isInRect(r_wc(1:2)+[stance/2 ; 0],r_wb(1:2),yaw_b,1,1);
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
    else
        plotColor = 'black';
    end
    
    % Decrease health bar
    health = health - lossfactor*sum(inRects);
    
    % Penalize leaving the arena
    if r_wc(1) < arena_w(1,1) || r_wc(1) > arena_w(1,2)
        plotColor = 'red';
        health = health - 1;
    end
    
    % If health drains completely, game is over; otherwise, decrease health
    % bar
    if health < 0
        condition = false;
        figure(1)
        text(-0.6,0.4,'GAME OVER','Color','red','FontSize',36)
    else
        set(hhealth,'xdata',[0.8-0.006*health 0.8])
        set(thealth,'string',strcat(num2str(health),'%'))
    end
    
    % Plot the blocks
    plot2DBlocks(Blocks_c,f,hBlocks2D,plotColor)
    if plot3D
        plot3DBlocks(Blocks_w,hBlocks3D,plotColor)
        Xarena = [arena_w(1,1) arena_w(1,2) arena_w(1,3) arena_w(1,4) arena_w(1,1)];
        Yarena = [arena_w(2,1) arena_w(2,2) arena_w(2,3) arena_w(2,4) arena_w(2,1)];
        Zarena = [arena_w(3,1) arena_w(3,2) arena_w(3,3) arena_w(3,4) arena_w(3,1)];
        set(harena3D,'xdata',Xarena,'ydata',Yarena,'zdata',Zarena)
    end
    
    % Pause for 24 frames per second
    pause(1/24)
    
    % Increment accumulator
    acc = acc + 1;
    
%     frame = getframe(gcf); % Convert the current figure into a frame of a video
%     writeVideo(vidObj,frame); % Write frame into video object
end
% close(vidObj) % Close the video object once simulation is complete

%% Functions
function plot2DBlocks(Blocks,foclength,fighandles,plotColor)
for i = 1:length(Blocks)
    corners = Blocks{i};
    fighandle = fighandles(i);
    if mean(corners(2,:)) < 50 && mean(corners(2,:)) > 0.01
        project3Dto2DBlock(corners,foclength,fighandle,plotColor);
    end
end
end

function plot3DBlocks(Blocks,fighandles,plotColor)
for i = 1:length(Blocks)
    corners = Blocks{i};
    fighandle = fighandles(i);
    if mean(corners(2,:)) < 50 && mean(corners(2,:)) > 0.01
        plot3DBlock(corners,fighandle,plotColor);
    end
end
end

function project3Dto2DBlock(corners,foclength,fighandle,plotColor)
c1 = foclength*[(corners(1,1)/corners(2,1)) ; (corners(3,1)/corners(2,1))];
c2 = foclength*[(corners(1,2)/corners(2,2)) ; (corners(3,2)/corners(2,2))];
c3 = foclength*[(corners(1,3)/corners(2,3)) ; (corners(3,3)/corners(2,3))];
c4 = foclength*[(corners(1,4)/corners(2,4)) ; (corners(3,4)/corners(2,4))];
c5 = foclength*[(corners(1,5)/corners(2,5)) ; (corners(3,5)/corners(2,5))];
c6 = foclength*[(corners(1,6)/corners(2,6)) ; (corners(3,6)/corners(2,6))];
c7 = foclength*[(corners(1,7)/corners(2,7)) ; (corners(3,7)/corners(2,7))];
c8 = foclength*[(corners(1,8)/corners(2,8)) ; (corners(3,8)/corners(2,8))];

Xblock = [c1(1) c2(1) c4(1) c3(1) c1(1) c5(1) c6(1) c8(1) c7(1) c5(1) c6(1) c2(1) c4(1) c8(1) c7(1) c3(1)];
Yblock = [c1(2) c2(2) c4(2) c3(2) c1(2) c5(2) c6(2) c8(2) c7(2) c5(2) c6(2) c2(2) c4(2) c8(2) c7(2) c3(2)];
set(fighandle,'xdata',Xblock,'ydata',Yblock,'color',plotColor)
end

function project3Dto2DArena(arena,foclength,fighandle)
c1 = foclength*[(arena(1,1)/arena(2,1)) ; (arena(3,1)/arena(2,1))];
c2 = foclength*[(arena(1,2)/arena(2,2)) ; (arena(3,2)/arena(2,2))];
c3 = foclength*[(arena(1,3)/arena(2,3)) ; (arena(3,3)/arena(2,3))];
c4 = foclength*[(arena(1,4)/arena(2,4)) ; (arena(3,4)/arena(2,4))];

Xarena = [c1(1) c2(1) c3(1) c4(1) c1(1)];
Yarena = [c1(2) c2(2) c3(2) c4(2) c1(2)];
set(fighandle,'xdata',Xarena,'ydata',Yarena)
end

function plot3DBlock(corners,fighandle,plotColor)
Xblock = [corners(1,1) corners(1,2) corners(1,4) corners(1,3) corners(1,1) corners(1,5) corners(1,6) corners(1,8) corners(1,7) corners(1,5) corners(1,6) corners(1,2) corners(1,4) corners(1,8) corners(1,7) corners(1,3)];
Yblock = [corners(2,1) corners(2,2) corners(2,4) corners(2,3) corners(2,1) corners(2,5) corners(2,6) corners(2,8) corners(2,7) corners(2,5) corners(2,6) corners(2,2) corners(2,4) corners(2,8) corners(2,7) corners(2,3)];
Zblock = [corners(3,1) corners(3,2) corners(3,4) corners(3,3) corners(3,1) corners(3,5) corners(3,6) corners(3,8) corners(3,7) corners(3,5) corners(3,6) corners(3,2) corners(3,4) corners(3,8) corners(3,7) corners(3,3)];
set(fighandle,'xdata',Xblock,'ydata',Yblock,'zdata',Zblock,'color',plotColor)
end

function [hox, hoy, hoz] = plotOrigin(origin,angles,size,fignum,width)
px = size*[1 ; 0 ; 0];
py = size*[0 ; 1 ; 0];
pz = size*[0 ; 0 ; 1];
Rx = [cos(angles(1)) -sin(angles(1)) 0 ; sin(angles(1)) cos(angles(1)) 0 ; 0 0 1];
Ry = [cos(angles(2)) 0 sin(angles(2)) ; 0 1 0 ; -sin(angles(2)) 0 cos(angles(2))];
Rz = [1 0 0 ; 0 cos(angles(3)) -sin(angles(3)) ; 0 sin(angles(3)) cos(angles(3))];
R = Rx*Ry*Rz;
pxnew = origin + R*px;
pynew = origin + R*py;
pznew = origin + R*pz;
figure(fignum)
hold on
hox = plot3([origin(1) pxnew(1)],[origin(2) pxnew(2)],[origin(3) pxnew(3)],'r','linewidth',width);
hoy = plot3([origin(1) pynew(1)],[origin(2) pynew(2)],[origin(3) pynew(3)],'g','linewidth',width);
hoz = plot3([origin(1) pznew(1)],[origin(2) pznew(2)],[origin(3) pznew(3)],'b','linewidth',width);
drawnow
end

function inRect = isInRect(camera,block,angle,height,width)
x = camera - block;
R = [cos(-angle) -sin(-angle) ; sin(-angle) cos(-angle)];
xRot = R*x;
if xRot(1) > -width/2 && xRot(1) < width/2 && xRot(2) > -height/2 && xRot(2) < height/2
    inRect = true;
else
    inRect = false;
end
end