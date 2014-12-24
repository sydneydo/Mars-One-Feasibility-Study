%
% M1_mass_plotting.m
%
% Creator: Andrew Owens
% Last updated: 2014-12-23
%
% This script plots the mass delivered to the surface at each mission, in
% the stacked bar chart format.
%

% load data
BPS = csvread('sparesRequired_BPS.csv',0,0,[0 0 125 26]);
noBPS = csvread('sparesRequired_noBPS.csv',0,0,[0 0 113 26]);

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
%  17) Pre-Deploy Total
%  18) Crew 1 Total
%  19) Crew 2 Total
%  20) Crew 3 Total
%  21) Crew 4 Total
%  22) Crew 5 Total
%  23) Crew 6 Total
%  24) Crew 7 Total
%  25) Crew 8 Total
%  26) Crew 9 Total
%  27) Crew 10 Total

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
labels = {'Pre-Deploy (2022)','Crew 1 (2024)','Crew 2 (2026)',...
    'Crew 3 (2028)','Crew 4 (2030)','Crew 5 (2032)','Crew 6 (2034)',...
    'Crew 7 (2036)','Crew 8 (2038)','Crew 9 (2040)','Crew 10 (2042)'};
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
% stack element). Groups are missions (11), stacks are BPS/noBPS (2), and
% stack elements are mass values (9).
stackedBar1 = zeros(11,2,9);
% go through each mission and fill in accordingly

% Pre-deploy
stackedBar1(1,1,1) = sum(BPS(bpsPDISRU,1).*BPS(bpsPDISRU,12));
stackedBar1(1,2,1) = sum(noBPS(nobpsPDISRU,1).*noBPS(nobpsPDISRU,12));

stackedBar1(1,1,2) = sum(BPS(bpsHAB,1).*BPS(bpsHAB,12));
stackedBar1(1,2,2) = sum(noBPS(nobpsHAB,1).*noBPS(nobpsHAB,12));

stackedBar1(1,1,3) = sum(BPS(bpsECLSS,1).*BPS(bpsECLSS,12));
stackedBar1(1,2,3) = sum(noBPS(nobpsECLSS,1).*noBPS(nobpsECLSS,12));

stackedBar1(1,1,4) = sum(BPS(bpsISRU,1).*BPS(bpsISRU,12));
stackedBar1(1,2,4) = sum(noBPS(nobpsISRU,1).*noBPS(nobpsISRU,12));

stackedBar1(1,1,5) = sum(BPS(bpsEVA,1).*BPS(bpsEVA,12));
stackedBar1(1,2,5) = sum(noBPS(nobpsEVA,1).*noBPS(nobpsEVA,12));

% crewed missions
for j = 2:11
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
set(gca,'FontSize',14)
title('Breakdown of Mass Delivered Per Mission','FontSize',18,...
    'FontWeight','bold')
xlabel('Mission','FontSize',16)
ylabel('Mass Delivered to Surface [tonnes]','FontSize',16)
legend('PDISRU','Habitat and Crew Systems','ECLSS','ISRU','EVA',...
    'PDISRU Spares','ECLSS Spares','ISRU Spares','EVA Spares','Food',...
    'location','northwest')

%% Stacked Bar - Emplaced Mass, Spares, and Food
stackedBar2 = zeros(11,2,3);
stackedBar2(:,:,1) = sum(stackedBar1(:,:,1:5),3);
stackedBar2(:,:,2) = sum(stackedBar1(:,:,6:9),3);
stackedBar2(:,:,3) = stackedBar1(:,:,10);

% create plot
plotBarStackGroups(stackedBar2, labels)
set(gca,'FontSize',14)
title('Breakdown of Mass Delivered Per Mission','FontSize',18,...
    'FontWeight','bold')
xlabel('Mission','FontSize',16)
ylabel('Mass Delivered to Surface [tonnes]','FontSize',16)
legend('Emplaced Mass','Spare Parts','Food','location','northwest')