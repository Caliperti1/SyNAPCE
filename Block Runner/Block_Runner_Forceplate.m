
% =========================================================================
%         /                                                       \
%        /                                                         \
%       /                      Block Runner                         \
%      /                                                             \
%     /       A Matlab FPV Video Game with Force Plate Controls       \
%    /                                                                 \
%   /                                                                   \
%  /                                                                     \
% =========================================================================
%  Caspian Bell, J. Josiah Steckenrider
%  United States Military Academy
%  West Point, NY

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Game setup

close all
clc

% Define global variables for game
global r_wbs vfwd N arena_w harena f angle_wbs w corners_b stance pen lossfactor hBlocks2D sensitivity acc dist path condition sortv len wid mN rN lN COPx COPy T Note penalty vidObj secn n config vddist;

% Allows block locations to be randomized or follow a specific
% configuration (0 for random)
config=1;

% Initialize variable for the stored path
path = [];
dist = 0;

% Define translational and rotational "velocities"
vfwdbase = 0.1; % Translational forward
vfwd = vfwdbase;
w = 0.1; % Rotational

% Define force plate sensitivity
sensitivity = 30;

% Define camera focal length
f = 1; % Focal length

% Define width between feet 
stance = 0;

%Ask number of screens in order to graph in proper location
screens=input('How many screens are being used? ');

%Initialize parameters
COPx=[];
COPy=[];
Note=[];
T=[];
penalty=[];
secn=null(1,2);

% Initialize health level and loss factor
pen = 0;
lossfactor = -1;

% Get screen size
screen = get(0,'screensize');

% Define block corners in block reference frame
corners_b = [-0.5 -0.5 -0.5 -0.5 0.5 0.5 0.5 0.5 ; ...
             -0.5 -0.5 0.5 0.5 -0.5 -0.5 0.5 0.5 ; ...
             0 1 0 1 0 1 0 1]; % Origin is at bottom center of block

% Define arena boundaries
r_wa = [0 ; 0.1 ; 0]; % Vector to the back-left corner of the arena
wid = 10; % Width of arena
len = 20*wid; % Length of arena
arena_w = repmat(r_wa,1,4) + ...
    [0 wid wid 0 ; 0 0 len len ; 0 0 0 0]; % 4 corners of arena

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

% config=input("Enter block configuration (0 for random): "); % Allows program runner to input block configuration if uncommented
if config==0 
    % Randomly generate blocks
    rN = 100; % Number of random blocks
    blockxs = min(arena_w(1,:)) + wid*rand(1,rN); % Random x-coordinates of blocks
    blockys = min(arena_w(2,:))+2*len/3 +len*rand(1,rN)/3; % Random y-coordinates of blocks
    blockzs = zeros(1,rN);  % All blocks are positioned on the "floor"
    blockvs = zeros(1,rN);  % None of these blocks move laterally
    %r_wbs = [blockxs ; blockys ; blockzs]; % Stack all world-to-block position vectors
    %angle_wbs = [2*pi*rand(1,N) ; zeros(1,N) ; zeros(1,N)]; % Randomly generate block orientations
    
    % Gernerate moving blocks
    mN=40; % Number of moving blocks
    Vblk=.2; % Sets horixontal block velocity
    blockx=min(arena_w(1,:)) + wid*rand(1,rN); % Random x-coordinates of blocks
    blocky=(1:mN)*len/(mN*3)+len/3;
    blockz=zeros(1,mN);
    blockv=null(1,mN);
    for i=1:mN %  Half of the blocks start going to the right, half start going to the left
        if rand>.5
            blockv(i)=-Vblk;
        else 
            blockv(i)=Vblk;
        end
    end
    
    % Systematiclly generate lines of blocks
    l=8; % Number of blocks per line
    n=8; % Number of lines
    lN=l*n; % Number of blocks
    N=lN+rN+mN;
    ld=10; % Distance between lines 
    blocksx=null(1,lN);
    blocksy=null(1,lN);
    blocksz=zeros(1,lN);
    blocksv=zeros(1,lN);
    vd=randi([1 (l+1)],1,n); % Creates martix of openings
    kx=1; % Index for the next x value
    ky=1; % Index for the next y value
    for i=1:n % Iterates through each line
        for j=1:(l+1) % Iterates through each space on the line
            if vd(i)~=j % Skips the void spot
                blocksx(kx)=(j-.5)*wid/(l+1); % Sets a block at every non void x value
                kx=kx+1; % Increments the x index
            end
        end
        for j=1:l % Iterates through each block in a line
            blocksy(ky)=i*len/(3*n); % Sets the y value for each line evenly spaced out over the whole arena length
            ky=ky+1; % Increments the y index
        end
    end
    
    [sorty,sortIndex]=sort(cat(2,blocksy,blockys,blocky)); % Sorts all block arrays by y position
    catx=cat(2,blocksx,blockxs,blockx);
    catz=cat(2,blocksz,blockzs,blockz);
    catv=cat(2,blocksv,blockvs,blockv);
    sortx=catx(sortIndex);
    sortz=catz(sortIndex);
    sortv=catv(sortIndex);
    r_wbs = [sortx; sorty; sortz]; % Stack all world-to-block position vectors
elseif config==1 % Uses presaved block configuration
    r_wbs=[0.555555555555556,1.66666666666667,2.77777777777778,3.88888888888889,5,7.22222222222222,8.33333333333333,9.44444444444445,0.555555555555556,1.66666666666667,2.77777777777778,3.88888888888889,5,6.11111111111111,7.22222222222222,9.44444444444445,0.555555555555556,1.66666666666667,2.77777777777778,3.88888888888889,5,7.22222222222222,8.33333333333333,9.44444444444445,0.555555555555556,1.66666666666667,2.77777777777778,3.88888888888889,5,6.11111111111111,7.22222222222222,9.44444444444445,0.555555555555556,1.66666666666667,2.77777777777778,3.88888888888889,5,7.22222222222222,8.33333333333333,9.44444444444445,0.555555555555556,1.66666666666667,2.77777777777778,3.88888888888889,5,6.11111111111111,7.22222222222222,8.33333333333333,0.555555555555556,1.66666666666667,2.77777777777778,3.88888888888889,5,6.11111111111111,7.22222222222222,9.44444444444445,0.555555555555556,1.66666666666667,2.77777777777778,3.88888888888889,6.11111111111111,7.22222222222222,8.33333333333333,9.44444444444445,7.77232429234510,5.11064089112722,0.277500884482718,9.90385281566876,5.00939923753605,3.31997486961156,1.73883139944506,6.25636394848839,5.75134832806327,7.50985384525445,1.53518799776586,3.56787196602359,1.43950800246145,8.50607655245249,3.37869740308340,2.75196492845342,0.0601097311711618,8.01911968617498,4.97408284738571,5.37842841324121,8.70912524621325,7.22843568666448,6.68085931674845,1.78827792303708,5.50495354874599,9.59875078687972,5.96021671986299,8.08570708752388,9.84532354863445,8.85924447669938,2.13837003113112,0.346300613124667,4.51123791403174,0.137945567780947,4.73710749132909,9.51197090728795,2.48952278705433,3.86422800554417,4.31433376426054,8.30886484749040,2.82840091614325,9.46008945084062,0.538243021501204,8.93474311740186,6.96568689511640,8.76184335960346,7.30718017321590,9.37449567040730,1.20508166401978,4.61121079779699,5.66860831789241,7.58974161342075,0.272502196608165,4.96799421779149,1.87382889148607,2.59965278716868,8.11317420238023,2.26534462555839,5.97045229614403,6.20425185783994,2.88565308881261,2.69046814753517,6.78106077559796,3.71378578093092,3.16071200885960,4.30595200320603,4.94456347383399,9.86051066726614,5.17344133245693,6.78568638819314,5.60856738133542,6.14903565140055,8.01172362362499,0.478438001602993,5.09953037053204,3.68311038073403,7.26741468842694,0.738418767360661,0.646407594535227,7.42372334463615,6.80394991214306,0.224136544401531,0.915581428748301,0.538315489695107,1.44526906948512,5.15772858133538,9.08438370578178,6.37306290353483,0.909616879242212,5.31689585894733,3.70485792654012,3.56705749924566,7.34559125166410,0.677854884858151,9.97551902431370,5.19916824790401,3.19067820216784,0.782287091856850,6.22391433081251,7.18180905209727,4.75879024056308,6.10092246274455,2.03592380287419,2.61176170571255,4.56350723650029,5.64268825273198,4.20400431232813,3.55033321773383,8.62187431116879,2.04492581358956,5.13363986157654,2.05181251932987,8.97646542373691,7.47661582378364,9.81596208916383,0.524855426380236,9.54244324359415,0.380015353959609,7.38256992026790,1.10048497112667,3.14783504755494,4.65820073116048,7.52857841103010,8.50614066003707,3.98005186420214,4.39134081593786,5.48009157335659,7.90644897912478,1.40873797601841,0.986302372429138,9.38200405804263,9.93342763841508,4.13183358569897,0.774874815154217,4.42934666053870,3.79605285770611,6.55611090496500,5.94194175430363,9.90511215150315,2.40904799077728;8.33333333333333,8.33333333333333,8.33333333333333,8.33333333333333,8.33333333333333,8.33333333333333,8.33333333333333,8.33333333333333,16.6666666666667,16.6666666666667,16.6666666666667,16.6666666666667,16.6666666666667,16.6666666666667,16.6666666666667,16.6666666666667,25,25,25,25,25,25,25,25,33.3333333333333,33.3333333333333,33.3333333333333,33.3333333333333,33.3333333333333,33.3333333333333,33.3333333333333,33.3333333333333,41.6666666666667,41.6666666666667,41.6666666666667,41.6666666666667,41.6666666666667,41.6666666666667,41.6666666666667,41.6666666666667,50,50,50,50,50,50,50,50,58.3333333333333,58.3333333333333,58.3333333333333,58.3333333333333,58.3333333333333,58.3333333333333,58.3333333333333,58.3333333333333,66.6666666666667,66.6666666666667,66.6666666666667,66.6666666666667,66.6666666666667,66.6666666666667,66.6666666666667,66.6666666666667,68.3333333333333,70,71.6666666666667,73.3333333333333,75,76.6666666666667,78.3333333333333,80,81.6666666666667,83.3333333333333,85,86.6666666666667,88.3333333333333,90,91.6666666666667,93.3333333333333,95,96.6666666666667,98.3333333333333,100,101.666666666667,103.333333333333,105,106.666666666667,108.333333333333,110,111.666666666667,113.333333333333,115,116.666666666667,118.333333333333,120,121.666666666667,123.333333333333,125,126.666666666667,128.333333333333,130,131.666666666667,133.333333333333,133.553288258610,133.840520201773,133.933826939552,134.849303241463,135.608838140430,136.034865115176,137.045922757818,137.053156926665,137.120918132111,139.753845438904,140.985096834932,141.004422578136,141.320527322533,142.229831984061,142.235921157921,144.265099012659,144.715864176778,145.678379751075,145.883969617989,146.101698452819,146.941073077586,147.851747029101,149.558153009839,149.562455375113,149.601087259000,149.913323783044,150.122858835765,150.194231743721,151.420775511588,151.929247930366,152.638042921482,152.824022040603,152.828382479562,153.487272710715,153.719897922779,153.726905206231,153.971793894681,154.216996816554,155.563867972444,156.839895494307,157.071289412835,157.161474605559,158.414076076371,159.824730934313,159.915217362522,160.257571933670,162.562185382133,162.949331850916,163.497565952745,163.621495321603,165.394606957241,165.543798691504,165.600441158669,165.991975668331,166.074625969770,167.862160696593,169.651349026150,170.788887322708,171.099739539657,172.004820656907,172.982386162437,173.312968361985,173.720900375422,174.030763763592,174.281807169992,176.104967351183,176.391097212110,176.913306596543,179.362224239208,180.138634003676,180.680307798615,180.884250887685,182.035741023001,183.349799718864,183.686118227247,184.088787714639,185.506151060692,186.476108448447,186.642780946344,187.427586873614,188.566555437204,189.705381280516,190.220396800557,190.779349388469,190.877114994935,191.281785927325,191.669097097614,192.382087736430,192.468081832642,193.139768409626,193.164655376777,194.291695059103,194.465106602225,195.878907334822,196.501358359651,196.913673381496,197.946858879689,198.522300985295,199.416009470814,199.628562753600;0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
    sortv=[0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0.200000000000000	0.200000000000000	-0.200000000000000	0.200000000000000	-0.200000000000000	0.200000000000000	0.200000000000000	-0.200000000000000	0.200000000000000	-0.200000000000000	-0.200000000000000	-0.200000000000000	-0.200000000000000	-0.200000000000000	0.200000000000000	0.200000000000000	-0.200000000000000	0.200000000000000	-0.200000000000000	-0.200000000000000	-0.200000000000000	-0.200000000000000	0.200000000000000	0.200000000000000	-0.200000000000000	-0.200000000000000	-0.200000000000000	-0.200000000000000	-0.200000000000000	-0.200000000000000	-0.200000000000000	0.200000000000000	-0.200000000000000	0.200000000000000	-0.200000000000000	0.200000000000000	-0.200000000000000	0.200000000000000	0.200000000000000	-0.200000000000000	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0];
    l=8; % Inputs variables for preset block configuration
    n=8; 
    lN=l*n; 
    rN = 100;
    mN=40;
    N=lN+rN+mN;
    vd=[6,8,6,8,6,9,8,5];
    ld=10;
   
end
angle_wbs = [2*pi*rand(1,N) ; zeros(1,N) ; zeros(1,N)]; % Randomly generate block orientations
vddist=mean(abs(diff(vd)));


% Set up 2D plot
hfig = figure(1);
% hold on
p = get(0, "MonitorPositions"); 
hfig.Position=p(screens,:); % Needs to be 1
set(hfig,'units','normalized','WindowState','maximized')
% set(gcf,'units','normalized','outerposition',[1/3 1/4 1/3 1/2])
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
    
end

% Intro to game
figure(1)
ht1 = text(-0.6,0.65,'BLOCK RUNNER','Color','green','FontSize',28);
ht2 = text(-0.6,0.5,'Avoid the blocks','Color','black','FontSize',14);
ht3 = text(-0.6,0.4,'Stay inside the arena','Color','black','FontSize',14);
ht4 = text(-0.6,0.3,'Side-to-side: lean left and right','Color','black','FontSize',14);
ht5 = text(-0.6,0.2,'Press any key to start','Color','black','FontSize',14);

% Initialize accumulator and condition variables
acc = 0;
condition = true;
 
% Define global parameters for force plate interaction
global DLLInterface;
global DataHandler;
% global hscat;
 
% Initialize the force plate
status = DLLInitialize(true);
if status == 0
    % Fatal error: there's no DLL to attach to
    error('DLL not found - cannot run application');
end
 
% Start up the dynamic linked library
status = DLLStartup();
DataHandler.DeviceCount = status;
if ( status < 0 )
    % Show error
    disp('Cannot start DLL');    
else
    disp('DLL initialized');    
    % Show the device count
    numstring = sprintf(' %d',status);
    disp(numstring)
    % Set up the device list
    if ( status > 0 )
        titles = cell( 1, status );
        for i = 1 : status
            [ ~, AmpSN ]  = DLLGetAmpID( i );
            [ model, PlatSN ] = DLLGetPlatformID( i );
            tstr = sprintf( ' %d:  %-6s%-24s%s', i, AmpSN, model, PlatSN );
            titles{1,i} = tstr;
        end
    else
        titles = '     ';
    end
    disp(titles);
end
if ( status > 0 )
    CurrentAmp = 1;
else
    CurrentAmp = 0;
end
 
% Set everything up here so as to minimize processing during live data collection
if ~DLLInterface.Running
    
    % Set up data collection
    DataHandler.PacketCount = 0;
    DataHandler.LastIndex = 0;
    DataHandler.DataCount = 0;
    DataHandler.DataPointer = 1;
    DataHandler.AmpOffset = CurrentAmp - 1;
    DataHandler.BufferPoints = 10000;      %  NB: Must be a multiple of 16
 
    % Build the mask for data copying during collection
    ndev = DataHandler.DeviceCount;
    aoff = DataHandler.AmpOffset;
    DataHandler.DataMask = false( 1, ndev * 8 * 16 );
 
    % Set up all channels as active
    nactive = 6;
    DataHandler.DataMask( aoff*8 + 2 : 8*ndev : 128*ndev ) = true;
    DataHandler.DataMask( aoff*8 + 3 : 8*ndev : 128*ndev ) = true;
    DataHandler.DataMask( aoff*8 + 4 : 8*ndev : 128*ndev ) = true;
    DataHandler.DataMask( aoff*8 + 5 : 8*ndev : 128*ndev ) = true;
    DataHandler.DataMask( aoff*8 + 6 : 8*ndev : 128*ndev ) = true;
    DataHandler.DataMask( aoff*8 + 7 : 8*ndev : 128*ndev ) = true;
 
    DataHandler.ActiveChannels = nactive;
    DataHandler.DataLength = nactive * 16;
 
    DataHandler.BufferSize = DataHandler.BufferPoints * nactive;
    DataHandler.Buffer = zeros( 1, DataHandler.BufferSize );
 
    % Call the DLL start command
    DLLCollecting(true);
 
    disp('Starting data collection');
else
    % Call the DLL stop command
    DLLCollecting(false);
    pause( 0.2 );
 
    disp('Stopping data collection');
end
 
% Interface to data collection
DataHandler.Initialized = true;
DataHandler.CallbackCount = 0;
DataHandler.CallbackList = [];
DataHandler.PacketCount = 0;
DataHandler.ActiveChannels = 0;
DataHandler.FzCutoff = 1;
DataHandler.Sample = zeros(1,6);
DataHandler.COP.X = 0;
DataHandler.COP.Y = 0;
 
% Timer creation for data acquisition polling 
handles.AcquisitionTimer = timer;

% User begins the game by pressing a button
waitforbuttonpress
delete(ht1)
delete(ht2)   %signal assesment/seperation FFT
delete(ht3)
delete(ht4)
delete(ht5)

%Starts the time
tic

% This is where the juicy stuff actually happens
set(handles.AcquisitionTimer, 'Name', 'Acquisition timer');
set(handles.AcquisitionTimer, 'ExecutionMode', 'fixedRate');
set(handles.AcquisitionTimer, 'Period', 0.03);
set(handles.AcquisitionTimer, 'TimerFcn', {@DLLAcquisition_Block_Runner});

start(handles.AcquisitionTimer)

% Pause until user presses key to end game
pause

% Close things down
% close(vidObj) % Close the video object once simulation is complete
tmrs = [handles.AcquisitionTimer];
for tmr = tmrs
    if tmr.Running
        stop(tmr);
        pause( 0.3 );
    end
    delete(tmr);
end
disp('Closing down the application');
DLLInitialize(false);



