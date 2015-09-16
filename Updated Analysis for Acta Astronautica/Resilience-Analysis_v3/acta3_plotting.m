% acta3_plotting.m
% Creator: Andrew Owens         Last Updated: 2015-09-10
% Creates plots required for the paper:
%   1) grouped stacked bar plot of mass delivered per mission, showing bars
%      for both the BPS and SF cases with stacks of the subsystem masses.
%      This version without power and thermal
%   2) same as above, but with power and thermal

% Load data (units are metric tons)
% Reads a .csv file that contains the raw numbers migrated over from the
% MEL. There are two files, one for BPS and one for SF. Rows are the
% requried mass for each particular subsystem (emplaced and spares):
%   1) Power
%   2) Thermal
%   3) Habitat, Crew Systems, Storage
%   4) ISRU (Crew or Pre Deploy)
%   5) BPS
%   6) ECLS
%   7) Food
%   8) ISRU Spares (Crew and Pre Deploy)
%   9) BPS Spares
%  10) ECLS Spares
% Columns are the missions from Pre-Deploy to Crew 10 (11 columns total).
% Each entry is the mass [t] of that row that must be delivered in that
% column.
bps = csvread('BPS_massPerMission_grouped.csv');
sf = csvread('SF_massPerMission_grouped.csv');

% Generate 3D matrix for stacked bar graph. Entries are (group, stack,
% stack element). Groups are missions (11), stacks are BPS/SF (2), and
% stack elements are subsystem mass values (10)
stackedBar1 = zeros(11,2,10);

% insert values
for j = 1:11
    for k = 1:10
        stackedBar1(j,1,k) = bps(k,j);
        stackedBar1(j,2,k) = sf(k,j);
    end
end

% create x axis labels
Xlabels = {'Pre-Deploy','Crew 1','Crew 2','Crew 3','Crew 4','Crew 5',...
    'Crew 6','Crew 7','Crew 8','Crew 9','Crew 10'};

legendLabels = {'Power','Thermal','Habitat,Crew Systems,Storage',...
    'ISRU','BPS','ECLS','Food','ISRU Spares',...
    'BPS Spares','ECLS Spares'};


% create plot
plotBarStackGroups(stackedBar1, Xlabels)
title('Mass Delivered Per Mission')
xlabel('Mission')
ylabel('Mass Delivered to Surface [t]')
legend(legendLabels,'location','northwest')

% set properties
grid on
ax = gca;
ax.XLim = [0.5, 11.5];
ax.FontSize = 16;
ax.TitleFontSizeMultiplier = 1.25;
ax.LabelFontSizeMultiplier = 1.15;
ax.TitleFontWeight = 'bold';