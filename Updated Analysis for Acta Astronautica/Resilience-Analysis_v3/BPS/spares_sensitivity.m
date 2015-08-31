% spares_sensitivity.m
% Creator: Andrew Owens         Last Updated: 2015-08-12
% Sensitivity analysis on the mass of spares required to achieve a given
% level of confidence.

% load PMFs
load Acta3_BPS_PMFs.mat

nComponents = size(componentPMFs,1);
% nComponents = 61;


Prange = 0:0.001:0.999;

masses = csvread('BPS_masses.csv');
masses = masses(1:nComponents); % take out ISRU

sparesMass = zeros(size(Prange));

scheduled = duration./componentData(:,3);
scheduled(isinf(scheduled)) = 0;
scheduled = componentData(:,4).*floor(scheduled);

% determine number of spares required for each one
for j = 1:length(Prange)
    bigP = Prange(j);
    p = bigP^(1/nComponents);
    manifest = zeros(nComponents,1);
    
    % random
    for k = 1:nComponents
        thisCDF = cumsum(componentPMFs{k,1});
        thisRandom = find(thisCDF>=p,1,'first')-1;
        thisScheduled = scheduled(k);
        manifest(k) = max(thisRandom, thisScheduled);
    end
    
    sparesMass(j) = manifest'*masses;
end

% redo with doubled reliability
load Acta3_BPS_PMFs_MTBFx2
nComponents = size(componentPMFs,1);

for j = 1:length(Prange)
    bigP = Prange(j);
    p = bigP^(1/nComponents);
    manifestX2 = zeros(nComponents,1);
    
    % random
    for k = 1:nComponents
        thisCDF = cumsum(componentPMFs{k,1});
        thisRandom = find(thisCDF>=p,1,'first')-1;
        thisScheduled = scheduled(k);
        manifestX2(k) = max(thisRandom, thisScheduled);
    end
    
    sparesMassX2(j) = manifestX2'*masses;
end


figure('Color','k')
fig = gcf;
fig.InvertHardcopy = 'off';
plot(Prange,sparesMass,'color',[91 155 213]./255,'linewidth',5)
hold on
%plot(Prange,sparesMassX2,'color',[237 125 49]./255,'linewidth',5)
plot([Prange(1) Prange(end)],[2500 2500],'--','color',[0.5 0.5 0.5])
plot([Prange(1) Prange(end)],[5000 5000],'--','color',[0.5 0.5 0.5])
plot([Prange(1) Prange(end)],[7500 7500],'--','color',[0.5 0.5 0.5])
plot([Prange(1) Prange(end)],[10000 10000],'--','color',[0.5 0.5 0.5])
xlim([0 1])
ylim([0 11000])
ax = gca;
ax.FontSize = 22;
ax.FontWeight = 'bold';
ax.Color = 'none';
ax.LineWidth = 1.5;
ax.XColor = 'white';
ax.YColor = 'white';
ax.XTick = 0:0.1:1;
ax.YTick = 0:1000:11000;

% figure('Color','k')
% fig = gcf;
% fig.InvertHardcopy = 'off';
% plot(Prange,sparesMass,'color',[91 155 213]./255,'linewidth',2)
% hold on
% plot(Prange,sparesMassX2,'--','color',[91 155 213]./255,'linewidth',2)
% plot([Prange(1) Prange(end)],[2500 2500],'color',[237 125 49]./255)
% plot([Prange(1) Prange(end)],[5000 5000],'color',[237 125 49]./255)
% plot([Prange(1) Prange(end)],[7500 7500],'color',[237 125 49]./255)
% plot([Prange(1) Prange(end)],[10000 10000],'color',[237 125 49]./255)
% xlim([0.9 1])
% ylim([5000 11000])
% ax = gca;
% ax.FontSize = 14;
% ax.FontWeight = 'bold';
% ax.Color = 'none';
% ax.LineWidth = 1.5;
% ax.XColor = 'white';
% ax.YColor = 'white';
% ax.XTick = 0.9:0.01:1;
% ax.YTick = 0:1000:11000;
