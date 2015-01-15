%
% M1_mass_plotting.m
%
% Creator: Andrew Owens
% Last updated: 2014-12-27
%
% This script plots the mass delivered to the surface at each mission, in
% the stacked bar chart format.
%

% load data
BPS = csvread('sparesRequired_BPS.csv',0,0,[0 0 125 56]);
noBPS = csvread('sparesRequired_noBPS.csv',0,0,[0 0 113 56]);

% fontsizes
titlesize = 18;
axtitlesize = 16;
ticklabelsize = 16;

% number of crews to plot (doesn't include pre-deploy)
nCrewsPlotted = 10;

preDeployCol = 32;

% Columns are:
%   1) Mass [kg]
%   2) Volume [m^3]
%   3) MTBF [h]
%   4) Life Limit [yr]
%   5) # in Primary System
%   6) # in Secondary System
%   7) Crew 1 Spare Parts
%   8) Crew 2 Spare Parts
%   9) Crew 3 Spare Parts
%  10) Crew 4 Spare Parts
%  11) Crew 5 Spare Parts
%  12) Crew 6 Spare Parts
%  13) Crew 7 Spare Parts
%  14) Crew 8 Spare Parts
%  15) Crew 9 Spare Parts
%  16) Crew 10 Spare Parts
%  17) Crew 11 Spare Parts
%  18) Crew 12 Spare Parts
%  19) Crew 13 Spare Parts
%  20) Crew 14 Spare Parts
%  21) Crew 15 Spare Parts
%  22) Crew 16 Spare Parts
%  23) Crew 17 Spare Parts
%  24) Crew 18 Spare Parts
%  25) Crew 19 Spare Parts
%  26) Crew 20 Spare Parts
%  27) Crew 21 Spare Parts
%  28) Crew 22 Spare Parts
%  29) Crew 23 Spare Parts
%  30) Crew 24 Spare Parts
%  31) Crew 25 Spare Parts
%  32) Pre-Deploy Total
%  33) Crew 1 Total
%  34) Crew 2 Total
%  35) Crew 3 Total
%  36) Crew 4 Total
%  37) Crew 5 Total
%  38) Crew 6 Total
%  39) Crew 7 Total
%  40) Crew 8 Total
%  41) Crew 9 Total
%  42) Crew 10 Total
%  43) Crew 11 Total
%  44) Crew 12 Total
%  45) Crew 13 Total
%  46) Crew 14 Total
%  47) Crew 15 Total
%  48) Crew 16 Total
%  49) Crew 17 Total
%  50) Crew 18 Total
%  51) Crew 19 Total
%  52) Crew 20 Total
%  53) Crew 21 Total
%  54) Crew 22 Total
%  55) Crew 23 Total
%  56) Crew 24 Total
%  57) Crew 25 Total

% Key rows in BPS:
%   1-66: ECLSS
%   67-75: Crew Systems ISRU
%   77-84: Pre-Deployed ISRU
%   85-92: Storage (part of ECLSS)
%   93: Food
%   94: Habitat Structure
%   95-124: Crew Systems
%   125-126: EVA (battery is 126)
%
% Key rows in noBPS
%   1-54: ECLSS
%   55-63: Crew Systems ISRU
%   64-72: Pre-Deployed ISRU
%   73-80: Storage (part of ECLSS)
%   81: Food
%   82: Habitat Structure
%   83-112: Crew Systems
%   113-114: EVA (battery is 113)

%% Stacked Bar - full breakdown
% for stacked bar chart 1, breakdown is:
%   1) Pre-Deployed ISRU Emplaced Mass
%   2) Habitat Structure and Crew Systems Emplaced Mass (there are no
%      spares)
%   3) ECLSS Emplaced Mass (including storage)
%   4) Crew Systems ISRU Emplaced Mass
%   5) EVA Emplaced Mass
%   6) PDISRU Spares
%   7) ECLSS Spares
%   8) ISRU Spares
%   9) EVA Spares
%  10) Food
% for both BPS and no BPS at each mission
% labels = {'Pre-Deploy (2022)','Crew 1 (2024)','Crew 2 (2026)',...
%     'Crew 3 (2028)','Crew 4 (2030)','Crew 5 (2032)','Crew 6 (2034)',...
%     'Crew 7 (2036)','Crew 8 (2038)','Crew 9 (2040)','Crew 10 (2042)',...
%     'Crew 11 (2044)','Crew 12 (2046)','Crew 13 (2048)','Crew 14 (2050)',...
%     'Crew 15 (2052)','Crew 16 (2054)','Crew 17 (2056)','Crew 18 (2058)',...
%     'Crew 19 (2060)','Crew 20 (2062)','Crew 21 (2064)','Crew 22 (2066)',...
%     'Crew 23 (2068)','Crew 24 (2070)','Crew 25 (2072)'};

labels = {'Pre-Deploy','Crew 1','Crew 2',...
    'Crew 3','Crew 4','Crew 5','Crew 6',...
    'Crew 7','Crew 8','Crew 9','Crew 10',...
    'Crew 11','Crew 12','Crew 13','Crew 14',...
    'Crew 15','Crew 16','Crew 17','Crew 18',...
    'Crew 19','Crew 20','Crew 21','Crew 22',...
    'Crew 23','Crew 24','Crew 25'};

% labels = labels{1:nCrewsPlotted+1};
% 
% labels = {{'Pre-Deploy';'2022'},{'Crew 1';'2024'},{'Crew 2';'2026'},...
%     {'Crew 3';'2028'},{'Crew 4';'2030'},{'Crew 5';'2032'}};

bpsPDISRU = 77:84;
nobpsPDISRU = 64:72;
bpsHAB = 94:124;
nobpsHAB = 82:112;
bpsECLSS = [1:66, 85:92];
nobpsECLSS = [1:54, 73:80];
bpsFOOD = 93;
nobpsFOOD = 81;
bpsISRU = 67:75;
nobpsISRU = 55:63;
bpsEVA = 125:126;
nobpsEVA = 113:114;

% generate 3D matrix for stacked bar graph. Entries are (group, stack,
% stack element). Groups are missions (26), stacks are BPS/noBPS (2), and
% stack elements are mass values (10).
stackedBar1 = zeros(nCrewsPlotted+1,2,10);
% go through each mission and fill in accordingly

% Pre-deploy
stackedBar1(1,1,1) = sum(BPS(bpsPDISRU,1).*BPS(bpsPDISRU,preDeployCol));
stackedBar1(1,2,1) = sum(noBPS(nobpsPDISRU,1).*noBPS(nobpsPDISRU,preDeployCol));

stackedBar1(1,1,2) = sum(BPS(bpsHAB,1).*BPS(bpsHAB,preDeployCol));
stackedBar1(1,2,2) = sum(noBPS(nobpsHAB,1).*noBPS(nobpsHAB,preDeployCol));

stackedBar1(1,1,3) = sum(BPS(bpsECLSS,1).*BPS(bpsECLSS,preDeployCol));
stackedBar1(1,2,3) = sum(noBPS(nobpsECLSS,1).*noBPS(nobpsECLSS,preDeployCol));

stackedBar1(1,1,4) = sum(BPS(bpsISRU,1).*BPS(bpsISRU,preDeployCol));
stackedBar1(1,2,4) = sum(noBPS(nobpsISRU,1).*noBPS(nobpsISRU,preDeployCol));

stackedBar1(1,1,5) = sum(BPS(bpsEVA,1).*BPS(bpsEVA,preDeployCol));
stackedBar1(1,2,5) = sum(noBPS(nobpsEVA,1).*noBPS(nobpsEVA,preDeployCol));

% crewed missions
for j = 2:nCrewsPlotted+1
    stackedBar1(j,1,2) = sum(BPS(bpsHAB,1).*BPS(bpsHAB,5)) + ...
        sum(BPS(bpsHAB,1).*BPS(bpsHAB,6));
    stackedBar1(j,2,2) = sum(noBPS(nobpsHAB,1).*noBPS(nobpsHAB,5)) + ...
        sum(noBPS(nobpsHAB,1).*noBPS(nobpsHAB,6));
    
    stackedBar1(j,1,3) = sum(BPS(bpsECLSS,1).*BPS(bpsECLSS,5)) + ...
        sum(BPS(bpsECLSS,1).*BPS(bpsECLSS,6));
    stackedBar1(j,2,3) = sum(noBPS(nobpsECLSS,1).*noBPS(nobpsECLSS,5)) + ...
        sum(noBPS(nobpsECLSS,1).*noBPS(nobpsECLSS,6));
    
    stackedBar1(j,1,4) = sum(BPS(bpsISRU,1).*BPS(bpsISRU,5)) + ...
        sum(BPS(bpsISRU,1).*BPS(bpsISRU,6));
    stackedBar1(j,2,4) = sum(noBPS(nobpsISRU,1).*noBPS(nobpsISRU,5)) + ...
        sum(noBPS(nobpsISRU,1).*noBPS(nobpsISRU,6));
    
    stackedBar1(j,1,5) = sum(BPS(bpsEVA,1).*BPS(bpsEVA,5)) + ...
        sum(BPS(bpsEVA,1).*BPS(bpsEVA,6));
    stackedBar1(j,2,5) = sum(noBPS(nobpsEVA,1).*noBPS(nobpsEVA,5)) + ...
        sum(noBPS(nobpsEVA,1).*noBPS(nobpsEVA,6));
    
    stackedBar1(j,1,6) = sum(BPS(bpsPDISRU,1).*BPS(bpsPDISRU,5+j));
    stackedBar1(j,2,6) = sum(noBPS(nobpsPDISRU,1).*noBPS(nobpsPDISRU,5+j));
    
    stackedBar1(j,1,7) = sum(BPS(bpsECLSS,1).*BPS(bpsECLSS,5+j));
    stackedBar1(j,2,7) = sum(noBPS(nobpsECLSS,1).*noBPS(nobpsECLSS,5+j));
    
    stackedBar1(j,1,8) = sum(BPS(bpsISRU,1).*BPS(bpsISRU,5+j));
    stackedBar1(j,2,8) = sum(noBPS(nobpsISRU,1).*noBPS(nobpsISRU,5+j));
    
    stackedBar1(j,1,9) = sum(BPS(bpsEVA,1).*BPS(bpsEVA,5+j));
    stackedBar1(j,2,9) = sum(noBPS(nobpsEVA,1).*noBPS(nobpsEVA,5+j));
    
    stackedBar1(j,1,10) = sum(BPS(bpsFOOD,1).*BPS(bpsFOOD,5)) + ...
        sum(BPS(bpsFOOD,1).*BPS(bpsFOOD,6)) + ...
        sum(BPS(bpsFOOD,1).*BPS(bpsFOOD,5+j));
    
    stackedBar1(j,2,10) = sum(noBPS(nobpsFOOD,1).*noBPS(nobpsFOOD,5)) + ...
        sum(noBPS(nobpsFOOD,1).*noBPS(nobpsFOOD,6)) + ...
        sum(noBPS(nobpsFOOD,1).*noBPS(nobpsFOOD,5+j));
end

% convert from kg to tonnes
stackedBar1 = stackedBar1./1000;

% create plot
plotBarStackGroups(stackedBar1, labels)
set(gca,'FontSize',ticklabelsize)
title('Breakdown of Mass Delivered Per Mission','FontSize',titlesize,...
    'FontWeight','bold')
xlabel('Mission','FontSize',axtitlesize,'FontWeight','bold')
ylabel('Mass Delivered to Surface [tonnes]','FontSize',axtitlesize,...
    'FontWeight','bold')
legend('PDISRU','Habitat and Crew Systems','ECLSS','ISRU','EVA',...
    'PDISRU Spares','ECLSS Spares','ISRU Spares','EVA Spares','Food',...
    'location','northwest')
set(gca,'XTickLabelRotation',30)
xlim([0.5 nCrewsPlotted+1.5])

%% Stacked Bar - Emplaced Mass, Spares, and Food
stackedBar2 = zeros(nCrewsPlotted+1,2,3);
stackedBar2(:,:,1) = sum(stackedBar1(:,:,1:5),3);
stackedBar2(:,:,2) = sum(stackedBar1(:,:,6:9),3);
stackedBar2(:,:,3) = stackedBar1(:,:,10);

% create plot
plotBarStackGroups(stackedBar2, labels)
set(gca,'FontSize',ticklabelsize)
title('Breakdown of Mass Delivered Per Mission','FontSize',titlesize,...
    'FontWeight','bold')
xlabel('Mission','FontSize',axtitlesize,'FontWeight','bold')
ylabel('Mass Delivered to Surface [tonnes]','FontSize',axtitlesize,...
    'FontWeight','bold')
legend('Emplaced Mass','Spare Parts','Food','location','northwest')
set(gca,'XTickLabelRotation',30)
xlim([0.5 nCrewsPlotted+1.5])

%% Cumulative Mass Delivered
totalMass = sum(stackedBar2,3);
cumulativeMass = cumsum(totalMass,1);

% create plot
figure
plot(cumulativeMass(:,1),'r*-')
hold on
plot(cumulativeMass(:,2),'b*-')
set(gca,'FontSize',ticklabelsize)
title('Cumulative Mass Delivered To Surface','FontSize',titlesize,...
    'FontWeight','bold')
xlabel('Mission','FontSize',axtitlesize,'FontWeight','bold')
ylabel('Cumulative Mass Delivered to Surface [tonnes]','FontSize',...
    axtitlesize,'FontWeight','bold')
legend('BPS','No BPS','location','northwest')
ax = gca;
ax.XTickLabel = labels;
set(gca,'XTick',1:26,'XTickLabelRotation',30)
xlim([0.5 nCrewsPlotted+1.5])

%% Spare Parts Mass
sparePartsMass = stackedBar1(2:nCrewsPlotted+1,:,6:9);

labels2 = {'Crew 1','Crew 2',...
    'Crew 3','Crew 4','Crew 5','Crew 6',...
    'Crew 7','Crew 8','Crew 9','Crew 10',...
    'Crew 11','Crew 12','Crew 13','Crew 14',...
    'Crew 15','Crew 16','Crew 17','Crew 18',...
    'Crew 19','Crew 20','Crew 21','Crew 22',...
    'Crew 23','Crew 24','Crew 25'};

% create plot
plotBarStackGroups(sparePartsMass, labels2)
set(gca,'FontSize',ticklabelsize)
title('Mass of Spare Parts Delivered Per Mission','FontSize',titlesize,...
    'FontWeight','bold')
xlabel('Mission','FontSize',axtitlesize,'FontWeight','bold')
ylabel('Mass of Spare Parts [tonnes]','FontSize',axtitlesize,...
    'FontWeight','bold')
legend('PDISRU Spares','ECLSS Spares','ISRU Spares','EVA Spares',...
    'location','northwest')
set(gca,'XTickLabelRotation',30)
xlim([0.5 nCrewsPlotted+0.5])

%% MTBF Sensitivity

% load doubled MTBF data
BPS_x2 = csvread('sparesRequired_BPS_MTBFx2.csv',0,0,[0 0 125 56]);
noBPS_x2 = csvread('sparesRequired_noBPS_MTBFx2.csv',0,0,[0 0 113 56]);

% generate 3D matrix for stacked bar graph. Entries are (group, stack,
% stack element). Groups are missions (26), stacks are BPS/noBPS (2), and
% stack elements are mass values (10).
stackedBarx2 = zeros(nCrewsPlotted+1,2,10);
% go through each mission and fill in accordingly

% Pre-deploy
stackedBarx2(1,1,1) = sum(BPS_x2(bpsPDISRU,1).*BPS_x2(bpsPDISRU,preDeployCol));
stackedBarx2(1,2,1) = sum(noBPS_x2(nobpsPDISRU,1).*noBPS_x2(nobpsPDISRU,preDeployCol));

stackedBarx2(1,1,2) = sum(BPS_x2(bpsHAB,1).*BPS_x2(bpsHAB,preDeployCol));
stackedBarx2(1,2,2) = sum(noBPS_x2(nobpsHAB,1).*noBPS_x2(nobpsHAB,preDeployCol));

stackedBarx2(1,1,3) = sum(BPS_x2(bpsECLSS,1).*BPS_x2(bpsECLSS,preDeployCol));
stackedBarx2(1,2,3) = sum(noBPS_x2(nobpsECLSS,1).*noBPS_x2(nobpsECLSS,preDeployCol));

stackedBarx2(1,1,4) = sum(BPS_x2(bpsISRU,1).*BPS_x2(bpsISRU,preDeployCol));
stackedBarx2(1,2,4) = sum(noBPS_x2(nobpsISRU,1).*noBPS_x2(nobpsISRU,preDeployCol));

stackedBarx2(1,1,5) = sum(BPS_x2(bpsEVA,1).*BPS_x2(bpsEVA,preDeployCol));
stackedBarx2(1,2,5) = sum(noBPS_x2(nobpsEVA,1).*noBPS_x2(nobpsEVA,preDeployCol));

% crewed missions
for j = 2:nCrewsPlotted+1
    stackedBarx2(j,1,2) = sum(BPS_x2(bpsHAB,1).*BPS_x2(bpsHAB,5)) + ...
        sum(BPS_x2(bpsHAB,1).*BPS_x2(bpsHAB,6));
    stackedBarx2(j,2,2) = sum(noBPS_x2(nobpsHAB,1).*noBPS_x2(nobpsHAB,5)) + ...
        sum(noBPS_x2(nobpsHAB,1).*noBPS_x2(nobpsHAB,6));
    
    stackedBarx2(j,1,3) = sum(BPS_x2(bpsECLSS,1).*BPS_x2(bpsECLSS,5)) + ...
        sum(BPS_x2(bpsECLSS,1).*BPS_x2(bpsECLSS,6));
    stackedBarx2(j,2,3) = sum(noBPS_x2(nobpsECLSS,1).*noBPS_x2(nobpsECLSS,5)) + ...
        sum(noBPS_x2(nobpsECLSS,1).*noBPS_x2(nobpsECLSS,6));
    
    stackedBarx2(j,1,4) = sum(BPS_x2(bpsISRU,1).*BPS_x2(bpsISRU,5)) + ...
        sum(BPS_x2(bpsISRU,1).*BPS_x2(bpsISRU,6));
    stackedBarx2(j,2,4) = sum(noBPS_x2(nobpsISRU,1).*noBPS_x2(nobpsISRU,5)) + ...
        sum(noBPS_x2(nobpsISRU,1).*noBPS_x2(nobpsISRU,6));
    
    stackedBarx2(j,1,5) = sum(BPS_x2(bpsEVA,1).*BPS_x2(bpsEVA,5)) + ...
        sum(BPS_x2(bpsEVA,1).*BPS_x2(bpsEVA,6));
    stackedBarx2(j,2,5) = sum(noBPS_x2(nobpsEVA,1).*noBPS_x2(nobpsEVA,5)) + ...
        sum(noBPS_x2(nobpsEVA,1).*noBPS_x2(nobpsEVA,6));
    
    stackedBarx2(j,1,6) = sum(BPS_x2(bpsPDISRU,1).*BPS_x2(bpsPDISRU,5+j));
    stackedBarx2(j,2,6) = sum(noBPS_x2(nobpsPDISRU,1).*noBPS_x2(nobpsPDISRU,5+j));
    
    stackedBarx2(j,1,7) = sum(BPS_x2(bpsECLSS,1).*BPS_x2(bpsECLSS,5+j));
    stackedBarx2(j,2,7) = sum(noBPS_x2(nobpsECLSS,1).*noBPS_x2(nobpsECLSS,5+j));
    
    stackedBarx2(j,1,8) = sum(BPS_x2(bpsISRU,1).*BPS_x2(bpsISRU,5+j));
    stackedBarx2(j,2,8) = sum(noBPS_x2(nobpsISRU,1).*noBPS_x2(nobpsISRU,5+j));
    
    stackedBarx2(j,1,9) = sum(BPS_x2(bpsEVA,1).*BPS_x2(bpsEVA,5+j));
    stackedBarx2(j,2,9) = sum(noBPS_x2(nobpsEVA,1).*noBPS_x2(nobpsEVA,5+j));
    
    stackedBarx2(j,1,10) = sum(BPS_x2(bpsFOOD,1).*BPS_x2(bpsFOOD,5)) + ...
        sum(BPS_x2(bpsFOOD,1).*BPS_x2(bpsFOOD,6)) + ...
        sum(BPS_x2(bpsFOOD,1).*BPS_x2(bpsFOOD,5+j));
    
    stackedBarx2(j,2,10) = sum(noBPS_x2(nobpsFOOD,1).*noBPS_x2(nobpsFOOD,5)) + ...
        sum(noBPS_x2(nobpsFOOD,1).*noBPS_x2(nobpsFOOD,6)) + ...
        sum(noBPS_x2(nobpsFOOD,1).*noBPS_x2(nobpsFOOD,5+j));
end

% convert from kg to tonnes
stackedBarx2 = stackedBarx2./1000;
totalMass2 = sum(stackedBarx2,3);

% plot all 4 datasets (BPS/noBPS, reg/x2 MTBF)
figure
plot(totalMass(:,1),'r-*')
hold on
plot(totalMass2(:,1),'r--*')
plot(totalMass(:,2),'b-*')
plot(totalMass2(:,2),'b--*')
set(gca,'FontSize',ticklabelsize)
title('Impact of Increased Component Reliability','FontSize',titlesize,...
    'FontWeight','bold')
xlabel('Mission','FontSize',axtitlesize,'FontWeight','bold')
ylabel('Mass Delivered to Surface Per Mission [tonnes]','FontSize',...
    axtitlesize,'FontWeight','bold')
legend('BPS','BPS (MTBFx2)','No BPS','No BPS (MTBFx2)','location','northwest')
ax = gca;
ax.XTickLabel = labels;
set(gca,'XTick',1:26,'XTickLabelRotation',30)
xlim([0.5 nCrewsPlotted+1.5])
ylim([0 140])

%% Plot launches and launch cost
launch = csvread('launches.csv',0,0,[0 0 3 10]);
nLaunch_BPS = launch(1,:) + [0, 4.*ones(1,nCrewsPlotted)];
nLaunch_noBPS = launch(3,:) + [0, 4.*ones(1,nCrewsPlotted)];
nLaunch_M1 = [6, 10.*ones(1,nCrewsPlotted)];

% setup dual axis
costOfLaunch = .3;  % $300 million per launch (0.3 billion)
ylimit = [0 45];
ntick = 10;
ytic = linspace(ylimit(1),ylimit(2),ntick);

figure
plot(nLaunch_BPS,'r-*')
hold on
plot(nLaunch_noBPS,'b-*')
plot(nLaunch_M1,'-*','color',[0.85 0.33 0.1])
set(gca,'FontSize',ticklabelsize)
title('Number and Cost of Launches','FontSize',titlesize,...
    'FontWeight','bold')
xlabel('Mission','FontSize',axtitlesize,'FontWeight','bold')
ylabel('Number of Launches','FontSize',axtitlesize,'FontWeight','bold')
legend('BPS','No BPS','Mars One Claim','location','northwest')
ax = gca;
ax.XTickLabel = labels;
set(ax,'XTick',1:26,'XTickLabelRotation',30)
set(ax,'ylim',ylimit,'ytick',ytic)
xlim([0.5 nCrewsPlotted+1.5])

ax2 = axes('Position',get(ax,'Position'),'YAxisLocation','right','color',...
    'none');
set(ax2,'ylim',ylimit*costOfLaunch,'ytick',ytic.*costOfLaunch,'xtick',...
    get(ax,'xtick'),'xticklabel','','FontSize',ticklabelsize)
ylabel('Cost of Launches [$B]','FontSize',axtitlesize,'FontWeight','bold')