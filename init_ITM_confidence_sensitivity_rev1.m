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
array_confidence=horzcat(1,10,50) %%%%%% confidence %
array_ConfPct=array_confidence/100; %%%%%% 
reliability=50;   %%%%%Reliability %
RelPct=reliability/100;
Polarity=1; %%%%%%1=Vertical, 0=Horizontal
pol = int32(1);       % Polarization (0 for horizontal, 1 for vertical)
FreqMHz=7145; %%%%%MHz
freq_ghz=FreqMHz/1000;


%%%%DSS-14
TxLat1 = 35.426;
TxLon1 = -116.8895;
TxHtm1 = 73;  %%%%%%%Meters

max_dist_km=500;
num_dist_steps=501;
[array_RxLat,array_RxLon]=track1(TxLat1,TxLon1,90,km2deg(max_dist_km),[],[],num_dist_steps);
array_RxLat(1)=[];
array_RxLon(1)=[];
array_RxHtm=ones(size(array_RxLat))*20; %%%%%meter

dist_array=linspace(0,max_dist_km,num_dist_steps);
dist_array(1)=[];

array_TxLat=ones(size(array_RxLat))*TxLat1;
array_TxLon=ones(size(array_RxLat))*TxLon1;
array_TxHtm=ones(size(array_RxLat))*TxHtm1;


% figure;
% geoplot(array_RxLat,array_RxLon,'or')
% hold on;
% geoplot(TxLat1,TxLon1,'sb')
% grid on;
% pause(1)
% saveas(gcf, char(strcat('Points_Maps.png')))
% pause(0.1)


Gt = 0;              % TX antenna gain (dBi)
Gr = 0;               % RX antenna gain (dBi)


[num_pts,~]=size(array_TxLat)
[num_con]=length(array_ConfPct)
array_dBloss=NaN(num_pts,num_con);  %%%%%%Path loss for each confidence.
for i=1:1:num_pts
    i/num_pts*100
    TxLat=array_TxLat(i);
    TxLon=array_TxLon(i);
    TxHtm=array_TxHtm(i);

    RxLat=array_RxLat(i);
    RxLon=array_RxLon(i);
    RxHtm=array_RxHtm(i);

    for j=1:1:num_con
        ConfPct=array_ConfPct(j);
        TerHandler=int32(1); % 0 for GLOBE, 1 for USGS
        TerDirectory='C:\USGS\';    %%%%%%%%%Where the terrain data is located
        [temp_dBloss, propmodeary, errnumary] =itmp.ITMp2pAryRels(TxHtm,RxHtm,Refractivity,Conductivity,Dielectric,FreqMHz,RadioClimate,Polarity,ConfPct,RelPct,TxLat,TxLon,RxLat,RxLon,TerHandler,TerDirectory);
        array_dBloss(i,j)=double(temp_dBloss)';
    end

end
table1=array2table(horzcat(dist_array',array_dBloss));
table1.Properties.VariableNames{1}='Distance_km';
for j=1:1:num_con
    table1.Properties.VariableNames{j+1}=strcat(num2str(array_confidence(j)),'%');
end
table1
tic;
writetable(table1,strcat('Pathloss_ITM_confidence',num2str(num_dist_steps),'.csv'));
toc;


figure;
hold on;
for j=1:1:num_con
    plot(dist_array,array_dBloss(:,j),':','LineWidth',2,'DisplayName',strcat(num2str(array_confidence(j)),'%'))
end
legend;
grid on;
xlabel('Distance [km]')
ylabel('Pathloss [dB]')
f = gcf;  % current figure
f.Position = [100 100 1200 800];
pause(0.1)
saveas(gcf, char(strcat('ITM_',num2str(num_dist_steps),'.png')))


