clear;
clc;
close all;
app=NaN(1);
format shortG
folder1='C:\Users\nlasorte\OneDrive - National Telecommunications and Information Administration\MATLAB2024\7GHz P2P-DSN';  %%%%%%%Change this to where you put this matlab file
cd(folder1)
addpath(folder1)
pause(0.1)

%load('PFLTest.mat','pfl')
%pfl'


p452_folder='C:\Users\nlasorte\OneDrive - National Telecommunications and Information Administration\MATLAB2024\7GHz P2P-DSN\P452Sample'
try
    NET.addAssembly(fullfile(p452_folder, 'P452.dll'));
    disp('Successfully loaded .NET assembly.');
catch ME
    error('MATLAB:DotNetAssemblyLoadError', ...
          'Failed to load the .NET assembly. Please ensure the path is correct and the file is a valid .NET DLL. Error: %s', ME.message);
end



tic;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Test to Check ITM/Terrain 
NET.addAssembly(fullfile('C:\USGS', 'SEADLib.dll')); %%%%%%Where the SEADLib.dll is located
itmp=ITMAcs.ITMP2P;


%%%%%%% 1 Equatorial, 2 Continental Subtorpical, 3 Maritime Tropical, 4 Desert, 5 Continental Temperate, 6 Maritime Over Land, 7 Maritime Over Sea
RadioClimate=int32(5); %%%Climate = 5
Refractivity=301; %%%%%N_0 = 301
Dielectric=25.0;
Conductivity=0.02;
confidence=5 %%%%%% confidence %
ConfPct=confidence/100; %%%%%% 
reliability=0.001;   %%%%%Reliability %
RelPct=reliability/100;
Polarity=1; %%%%%%1=Vertical, 0=Horizontal
pol = int32(1);       % Polarization (0 for horizontal, 1 for vertical)
FreqMHz=7145; %%%%%MHz
freq_ghz=FreqMHz/1000;


% Epsilon = 15
% Sigma = .005
% Mdvar = 0


%%%%DSS-14
TxLat1 = 35.426;
TxLon1 = -116.8895;
TxHtm1 = 73;  %%%%%%%Meters

max_dist_km=500;
num_dist_steps=100;
[array_RxLat,array_RxLon]=track1(TxLat1,TxLon1,90,km2deg(max_dist_km),[],[],num_dist_steps);
array_RxLat(1)=[];
array_RxLon(1)=[];
array_RxHtm=ones(size(array_RxLat))*20; %%%%%meter

dist_array=linspace(0,max_dist_km,num_dist_steps);
dist_array(1)=[];

array_TxLat=ones(size(array_RxLat))*TxLat1;
array_TxLon=ones(size(array_RxLat))*TxLon1;
array_TxHtm=ones(size(array_RxLat))*TxHtm1;


figure;
geoplot(array_RxLat,array_RxLon,'or')
hold on;
geoplot(TxLat1,TxLon1,'sb')
grid on;
pause(1)
saveas(gcf, char(strcat('Points_Maps.png')))
pause(0.1)



Gt = 0;              % TX antenna gain (dBi)
Gr = 0;               % RX antenna gain (dBi)

% % RxLat =  42.3805;
% % RxLon = -71.0468;
% % RxHtm = 20; %%%%Meters

[num_pts,~]=size(array_TxLat)
array_dBloss=NaN(num_pts,2);  %%%%%%1) ITM, 2) p452
for i=1:1:num_pts
    i/num_pts*100
    TxLat=array_TxLat(i);
    TxLon=array_TxLon(i);
    TxHtm=array_TxHtm(i);

    RxLat=array_RxLat(i);
    RxLon=array_RxLon(i);
    RxHtm=array_RxHtm(i);

    TerHandler=int32(1); % 0 for GLOBE, 1 for USGS
    TerDirectory='C:\USGS\';    %%%%%%%%%Where the terrain data is located
    [temp_dBloss, propmodeary, errnumary] =itmp.ITMp2pAryRels(TxHtm,RxHtm,Refractivity,Conductivity,Dielectric,FreqMHz,RadioClimate,Polarity,ConfPct,RelPct,TxLat,TxLon,RxLat,RxLon,TerHandler,TerDirectory);
    array_dBloss(i,1)=double(temp_dBloss)';

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Terrain Profile
    USGS3Secp = TerrainPcs.USGS;
    CoordTx = TerrainPcs.Geolocation(TxLat,TxLon);
    CoordRx = TerrainPcs.Geolocation(RxLat,RxLon);
    USGS3Secp.TerrainDataPath=  "C:\USGS";
    Elev=double(USGS3Secp.GetPathElevation(CoordTx,CoordRx,90,true));  %%%%%%%%%This is the "z" equivalent
    %%%%%%%Need to then get the distance array --> track2 or just calculate the
    %%%%%%%distance and divide by the number of element in Elev
    temp_dist_km=deg2km(distance(TxLat,TxLon,RxLat,RxLon));
    guess_num_steps=temp_dist_km*1000/90;
    %length(Elev)
    dist_km=linspace(0,temp_dist_km,length(Elev));

    za=ones(size(dist_km))*2;
    % Test Example: Zone
    % Example: Ground conductivity/permittivity related data (often zeros if not used)
    zone = int32(za);

    dct = max(dist_km);              % TX antenna discrimination (dB)
    dcr = max(dist_km);              % RX antenna discrimination (dB)
    press = 1013.0;      % Atmospheric pressure (hPa)
    temp = 15;        % Temperature
    try
        % The output will be a single double value.
        mapdirectory = 'maps';
        pathLoss = P452.P452Model.tl_p452mapdir(mapdirectory, freq_ghz, reliability,dist_km, Elev, Elev, zone,TxHtm,RxHtm,TxLon,TxLat,RxLon,RxLat,Gt,Gr, pol, dct, dcr, press, temp);
        array_dBloss(i,2)=pathLoss;
    catch ME
        error('MATLAB:DotNetMethodCallError', ...
            'Error calling the tl_p452 method. Please check input types and method signature. Error: %s', ME.message);
        pause;
    end

end
horzcat(dist_array',array_dBloss)


figure;
hold on;
plot(dist_array,array_dBloss(:,1),':b','LineWidth',2,'DisplayName','ITM')
plot(dist_array,array_dBloss(:,2),'--r','LineWidth',2,'DisplayName','P452')
legend;
grid on;
xlabel('Distance [km]')
ylabel('Pathloss [dB]')
saveas(gcf, char(strcat('ITM_vs_P452.png')))


