%
% BPS_sensitivity.m
%
% Creator: Andrew Owens
% Last Updated: 2015-03-25
%





% load previous data
load Acta2_noBPS_PMFs.mat

% Required probability for the entire system
overallProbability = 0.999;

% cutoff probability; probabilities less than this will be considered to be
% effectively 0
cutoff = 1e-10;

% EULER parameters - parameters for EULER numerical Laplace transform
% inversion
EULERparams = [11; 15; 18.4];

% time between resupply missions [~26 months]
duration = 19000/24;

% Number of missions (including first)
nMissions = 15;

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
componentData = csvread('componentData_noBPS.csv',1,3);

% multiply the MTBF by 2 (increase reliability of each component)
componentData(:,2) = 2.*componentData(:,2);

% multiple instances of the same processor are repeated as different
% groups. Groups are:
%   1) OGA
%   2) CDRA
%   3) CCAA (x4)
%   4) UPA
%   5) WPA
%   6) CRA
%   7) ISRU AP
%   8) ISRU SP
%   9) PDISRU AP
%  10) PDISRU SP
% Note that there are 4 copies of the CCAA, which are assumed to have
% commonality. Since the ISRU and PDISRU systems are different, they do not
% exhibit commonality and must be considered seperately.


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

% account for the fact that there are four instances of the CCAA
scheduled(CCAAstart:CCAAend,:) = 4.*scheduled(CCAAstart:CCAAend,:);

% using scheduled, generate the matrix of scheduled spares required given
% that a new crew arrives every 26 months.
netCumulativeDemand_sched = scheduled;
for j = 1:nMissions-1
    netCumulativeDemand_sched = netCumulativeDemand_sched + ...
        [zeros(size(scheduled,1),j), scheduled(:,1:size(scheduled,2)-j)];
end

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
save('Acta2_noBPS_CumulativeDemandData_999.mat','sparesDemand',...
    'sparesDemand_EVAbatt','netCumulativeDemand',...
    'netCumulativeDemand_rand','netCumulativeDemand_sched')

% write the results to a .csv file
csvwrite('Acta2_noBPS_netCumulativeDemand_999.csv',netCumulativeDemand);
csvwrite('Acta2_noBPS_SparesDemand_999.csv',sparesDemand);
csvwrite('Acta2_noBPS_SparesDemand_EVAbatt_999.csv',sparesDemand_EVAbatt);