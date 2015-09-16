%
% spares_required_BPS_main.m
%
% Creator: Andrew Owens
% Last updated: 2015-08-02
%
% This script executes the spares analysis for the first n crews of Mars
% One.
%

%% add SMP modules to path
addpath SMP-Modules

%% Set solution parameters
% Required probability for the entire system
overallProbability = 0.99;

% cutoff probability; probabilities less than this will be considered to be
% effectively 0
cutoff = 1e-8;

% EULER parameters - parameters for EULER numerical Laplace transform
% inversion
EULERparams = [11; 15; 18.4];

% time between resupply missions [~26 months, in days]
duration = 19000/24;

% Number of missions (including first, but not pre-deployment)
nMissions = 10;

% discretization size
dt = 1/24; % 1 hour timesteps

% Set up and solve SMP for each processor
% Processors are comprised of subassemblies. Since all processors are
% separated by buffers, each can be considered independently. Failure of a
% subassembly within a processor takes the entire processor online until
% the failed subassembly is replaced with a spare, at which point the
% processor is brought back to nominal working condition. Assume that all
% repairs require 12h with a standard deviation of 1 hour, and all failures
% are exponential.

% load component data. Columns are:
%   1) Group ID (for grouping of components into subsystems)
%   2) MTBF [d]
%   3) Life Limit [d]
%   4) # of the component in primary system
componentData = csvread('componentData_BPS.csv');

% % multiply the MTBF by 2 (increase the reliability of each component
% componentData(:,2) = 2.*componentData(:,2);

% multiple instances of the same processor are repeated as different
% groups. Groups are:
%   1) CDRRA
%   2) ORA
%   3) CCAA (x6)
%   4) UPA
%   5) WPA
%   6) GLS
%   7) ISRU AP
%   8) ISRU SP
%   9) CO2 Injection System
%  10) PDISRU AP
%  11) PDISRU SP
%  12) PDISRU OGA
% Note that there are 6 copies of the CCAA, which are assumed to have
% commonality. Since the ISRU and PDISRU systems are different, they do not
% exhibit commonality and must be considered seperately.

% not all systems run all the time, and the inclusion of plants impacts
% different system runtimes. In order to capture this impact, perform
% spares analysis using only actual runtime of the system. This makes the
% assumption that MTBF and lifetime values are based on runtime and not
% calendar time in order to investigate the impact of changes to runtime on
% spares requirements.
subSysRuntime = [19000; % CDRA
    9032; % ORA
    19000; % CCAA (x6)
    8577; % UPA
    2172; % WPA
    19000; % GLS
    19000; % ISRU AP
    19000; % ISRU SP
    19000; % CO2 Injection System
    19000; % PDISRU AP
    19000; % PDISRU SP
    19000]./24; % PDISRU OGA; remember to divide 24 to get days

%% Run Solver (only run this section if .mat file isn't available)
% Goal is to generate a PMF of the number of spares required for each
% individual component in the componentData list at each resupply
% opportunity for a single crew. Once those are determined, appropriate
% convolution can be carried out to determine the overall demand.

% store results as a [# of components]x[# of resupply missions] cell array,
% with each entry containing the PMF of the number of spares required for
% that component at that resupply opportunity
componentPMFs = cell(size(componentData,1),nMissions);

% generate repair distribution (12 h repair time, 1 h s.d.)
mttr = 12/24;
sdr = 1/24;
sig = sqrt(log(1+sdr^2/mttr^2)); % repair shape parameter
mu = log(mttr)-(1/2)*sig^2; % repair log-scale parameter
% last entry is the repair distribution
t = 0:dt:mttr+15*sdr; % go out to 15 standard deviations
repairpdf = (1./(t.*sqrt(2*pi).*sig)).*...
    exp(-(log(t)-mu).^2./(2*sig^2));
repairpdf(isnan(repairpdf)) = 0; % remove any NaNs, replace with 0
repairpdf = repairpdf(1:find(repairpdf>=cutoff,1,'last')); % trim to cutoff
repairpdf = repairpdf./(dt*sum(repairpdf)); % normalize

% the CCAA has 6 instantiations of identical hardware; convolve the demand
% PMFs for CCAA components with themselves 4x to get overall demand profile
% for all 6 systems. Find indices now, do convolution in for loop below
CCAAstart = find(componentData(:,1)==3);
CCAAend = find(componentData(:,1)==4)-1;

% find start of pre-deployed ISRU system
PDISRUstart = find(componentData(:,1)==10,1,'first');

% find threshold probability (depends on number of components). Have to
% account for multiple instantiations of CCAA and ISRU here
nComponents_total = sum(componentData(:,4)) + ...
    sum(5.*componentData(CCAAstart:CCAAend,4));
thresholdProbability = overallProbability^(1/nComponents_total);

% downtimes = zeros(nMissions,1);

% run through each mission
tic
for mission = 1:nMissions
    disp(['Calculating for Mission ' num2str(mission)])

    % run through each processor independently
    index = 1;
    
    % store downtime
    downtimes = zeros(max(componentData(:,1)),1);
    for j = 1:max(componentData(:,1))
        % split out the data corresponding to this processor
        thisGroup = componentData(componentData(:,1)==j,:);
        nComponents = size(thisGroup,1);
        
        % find operating time for this processor
        thisDuration = subSysRuntime(j);
        
        % find Laplace domain values corresponding to this duration
        sVals = getLaplacePoints(thisDuration*mission,EULERparams);
                
        % generate adjacency matrix for this processor. Since any single
        % failure takes the whole thing offline, this is simple to construct.
        [r,c,vals,adjMat] = getAdjMat(nComponents);
        
        % generate transitions (exponential failure for each component, plus
        % the repair distribution found before)
        transitions = cell(nComponents+1,1);
        for k = 1:nComponents
            % get MTBF value for this component. For multiple instances of the
            % same component, look at minimum of set of exponentially
            % distributed processes (i.e. divide MTBF by the number of
            % components)
            thisMTBF = thisGroup(k,2)/thisGroup(k,4);
            t = 0:dt:-thisMTBF*log(thisMTBF*cutoff);
            pdf = (1/thisMTBF).*exp(-(1/thisMTBF).*t);
            pdf = pdf./(dt*sum(pdf));     % normalize
            transitions{k} = [pdf; dt.*cumsum(pdf)];
        end
        transitions{end} = [repairpdf; dt.*cumsum(repairpdf)];
        
        % generate Q
        [Q,H] = makeKernel(r,c,vals,adjMat,size(adjMat,1),transitions);
        
        % get laplace transform LQ and LH
        LQ = getLT(Q,r,c,sVals,dt);
        Hindex = unique(r);
        LH = getLT(H,Hindex,ones(size(Hindex)),sVals,dt);
        for k = 1:length(LH)
            LH{k} = diag(LH{k});
        end
        
        % get downtime
        % (only examine downtime for one mission)
        [~,E] = getPandE(LQ,LH,sVals,1,EULERparams,thisDuration*mission);
        if j ~= 9 % don't count GLS time
            downtimes(j) = E(1);
        end
        
        
        % get Markov renewal probabilities
        v = getv(LQ,1,sVals,2:(nComponents+1),cutoff,EULERparams,...
            thisDuration*mission);
        
        % store results in componentPMFs array
        for k = 1:nComponents
            componentPMFs{index,mission} = v{k};
            index = index + 1;
        end
    end
    
    % convolve for 6 instantiations of CCAA
    for j = CCAAstart:CCAAend
        thisPMF = componentPMFs{j,mission};
        newPMF = conv(conv(conv(conv(conv(thisPMF,thisPMF),thisPMF),...
            thisPMF),thisPMF),thisPMF);
        componentPMFs{j,mission} = newPMF;
    end
    toc
    keyboard
end

% save the results so we don't have to do this again
save('Acta3_BPS_PMFs.mat','componentPMFs','overallProbability',...
    'thresholdProbability','nComponents','cutoff','dt','duration',...
    'nMissions','componentData','CCAAstart','CCAAend','PDISRUstart',...
    'downtimes');

%% Convolve results
% The PMFs generated above give the cumulative probabilistic demand for a
% single crew at each mission. To determine overall cumulative demand,
% convolve the probabilistic demand for each crew at each mission and use a
% probability threshold to select values. To go from cumulative demand to
% per-mission, simply take the discrete difference.

% load previous data
load Acta3_BPS_PMFs.mat

% preallocate the cell array indicating the net cumulative demand for each
% component at each mission. Some cells of this will be overwritten as
% needed.
netCumulativeDemandPMFs = componentPMFs;
netCumulativeDemand_rand = zeros(size(componentPMFs));

% note that the cumulative demand for the first mission is the same as the
% demand for one crew, since there is only one crew present. At each
% subsequent mission, need to convolve in the 2-mission demand for 1 crew
% and the 1-mission demand for 1 crew, and so on.
% Note that this operation is not necessary for the PDISRU systems, since
% they are refurbished by each crew; only one is operational at all times

for j = 2:nMissions
    for k = 1:PDISRUstart-1
        netCumulativeDemandPMFs{k,j} = conv(...
            netCumulativeDemandPMFs{k,j-1},componentPMFs{k,j});
    end
end

% use the overall probability threshold to determine the number of spares
% that must be manifested (this is cumulative, for all crews)
for j = 1:nMissions
    for k = 1:size(netCumulativeDemandPMFs,1)
        thisCDF = cumsum(netCumulativeDemandPMFs{k,j});
        netCumulativeDemand_rand(k,j) = ...
            find(thisCDF>=thresholdProbability,1)-1;
    end
end

% check the required spares for scheduled replacement. If the scheduled
% repairs is greater than the random repairs, use that number instead.
% scheduled is the cumulative number of spares required for scheduled for
% one crew.
scheduled = zeros(size(netCumulativeDemand_rand));
for j = 1:nMissions
    thisScheduled = duration*j./componentData(:,3);
    % replace inf with 0 - this indicates that the life limit is 0, or not
    % given
    thisScheduled(isinf(thisScheduled)) = 0;
    % multiply by the number of that element in the system and round down
    scheduled(:,j) = componentData(:,4).*floor(thisScheduled);
end

% adjust PDISRU scheduled demand; since there's only one system, there's
% only the scheduled demand present in the first row

% account for the fact that there are 6 instances of the CCAA
scheduled(CCAAstart:CCAAend,:) = 6.*scheduled(CCAAstart:CCAAend,:);

% using scheduled, generate the matrix of scheduled spares required given
% that a new crew arrives every 26 months.
netCumulativeDemand_sched = scheduled;
for j = 1:nMissions-1
    netCumulativeDemand_sched = netCumulativeDemand_sched + ...
        [zeros(size(scheduled,1),j), scheduled(:,1:size(scheduled,2)-j)];
end

% PDISRU system is only one system, so replace netCumulativeDemand with
% overall scheduled demand
netCumulativeDemand_sched(PDISRUstart:end,:) = scheduled(PDISRUstart:end,:);

% For demand prediction, take the maximum from either random failures or
% scheduled repair
netCumulativeDemand = max(netCumulativeDemand_rand,...
    netCumulativeDemand_sched);

% transform cumulative demand into per-launch demand
sparesDemand = diff([zeros(size(netCumulativeDemand,1),1),...
    netCumulativeDemand],1,2);

% Side calculation: calculate spares for scheduled replacement of EVA
% batteries
lifetime = 0.1230769231*365; % life limit based on 32 eva limit at 5 evas/wk
numBatt = 2; % number in system
cumulativeEVAbatt = zeros(1,nMissions);
for j = 1:nMissions
    cumulativeEVAbatt(j) = numBatt*floor(duration*j/lifetime);
end

netCumulativeEVAbatt = cumulativeEVAbatt;
for j = 1:nMissions-1
    netCumulativeEVAbatt = netCumulativeEVAbatt + ...
        [zeros(1,j), cumulativeEVAbatt(1:nMissions-j)];
end
sparesDemand_EVAbatt = diff([0 netCumulativeEVAbatt]);

% save outputs
save('Acta3_BPS_CumulativeDemandData.mat','sparesDemand',...
    'sparesDemand_EVAbatt','netCumulativeDemand',...
    'netCumulativeDemand_rand','netCumulativeDemand_sched')

% write the results to a .csv file
csvwrite('Acta3_BPS_netCumulativeDemand.csv',netCumulativeDemand);
csvwrite('Acta3_BPS_SparesDemand.csv',sparesDemand);
csvwrite('Acta3_BPS_SparesDemand_EVAbatt.csv',sparesDemand_EVAbatt);