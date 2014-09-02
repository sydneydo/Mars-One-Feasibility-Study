%
% getProcessorSparesData.m
%
% Creator: Andrew Owens
% Last updated: 2014-08-29
%
% This function calculates the spares probabilities for a given processor
%
% INPUTS:
%   processorData - matrix of doubles. Each row corresponds to a
%       subassembly; first column counts the number of spares and the
%       second column is the corresponding probability. Values range from
%       the lowest number of spares that yields a probability above
%       lowThreshold to the first number of spares that yields a
%       probability above highThreshold
%   lowThreshold - low-end threshold on probabilities. Only probabilities
%       above this threshold are kept for consideration.
%   highThreshold - high-end threshold on probabilities. Probabilities
%       above this threshold are considered to be effectively 1.
%   duration - time between resupply missions [h]. Probabilities are
%       calculated for this duration.
%
% OUTPUTS:
%   thisSet - cell array. Each cell corresponds to a subassembly in this
%       processor, and contains a matrix of doubles giving the number of
%       spares (first column) and the probability that that number is
%       sufficient (second column). Values are calculated such that the
%       lowest number of spares is the first that provides a probability
%       greater than lowThreshold and the highest is the first that
%       provides a probability higher than highThreshold.
%   thisLB - vector of doubles giving the lowest number of spares used for
%       each subassembly
%   thisUB - vector of doubles giving the highest number of spares used for
%       each subassembly
%

function [thisSet, thisLB, thisUB] = getProcessorSparesData(mtbf_vec,...
    lowThreshold,cutoff,highThreshold,duration,dt)

% processorData contains a set of subassemblies that can be analyzed with
% the assumption that only one failure occurs at a time (as constituent
% parts of a larger processor, when one of them fails the entire processor
% is taken offline until that one is repaired).

% set solver parameters
startState = 1; % state the system starts in 
EULERparams = [11; 15; 18.4]; % parameters for EULER numerical ILT

% convert mtbfs to days
mtbf_vec = mtbf_vec./24;

% set transition distributions
% exponential failure for each subassembly
lam_vec = 1./mtbf_vec;
transitions = cell(length(mtbf_vec)+1,1);
for j = 1:length(mtbf_vec)
    t = 0:dt:-mtbf_vec(j)*log(mtbf_vec(j)*cutoff);
    pdf = lam_vec(j).*exp(-lam_vec(j).*t);
    pdf = pdf./(dt*sum(pdf));     % normalize
    transitions{j} = [pdf; dt.*cumsum(pdf)];
end

% repair distribution (assume 12 h repair time, 1 h s.d.)
mttr = 12;
sdr = 1;
sig = sqrt(log(1+sdr^2/mttr^2)); % repair shape parameter
mu = log(mttr)-(1/2)*sig^2; % repair log-scale parameter
% entry 7 is the repair distribution
t = 0:dt:mttr+15*sdr; % go out to 15 standard deviations
pdf = (1./(t.*sqrt(2*pi).*sig)).*...
    exp(-(log(t)-mu).^2./(2*sig^2));
pdf(isnan(pdf)) = 0; % remove any NaNs, replace with 0
pdf = pdf(1:find(pdf>=cutoff,1,'last')); % trim the distribution to cutoff
pdf = pdf./(dt*sum(pdf)); % normalize
transitions{end} = [pdf; dt.*cumsum(pdf)]; % generate cdf and store results

% find number of states
nStates = length(mtbf_vec)+1;

% set adjacency data and form adjacency matrix
r = [ones(length(mtbf_vec),1); (2:length(mtbf_vec)+1)'];
c = [(2:length(mtbf_vec)+1)'; ones(length(mtbf_vec),1)];
vals = [(1:length(mtbf_vec))'; ...
    (length(mtbf_vec)+1).*ones(length(mtbf_vec),1)];
adjMat = sparse(r,c,vals);

% setup and solve SMP
[Q,~] = makeKernel(r,c,vals,adjMat,nStates,transitions);
sVals = getLaplacePoints(duration,EULERparams);
LQ = getLT(Q,r,c,sVals,dt); % get LQ

% get Markov renewal probabilities.
% VCDF is a matrix of doubles. Each row corresponds to a number of spares,
% starting at zero and recorded in the first column. Each subsequent column
% is the probablility of that number of spares being required for the
% subassembly. Subassemblies are listed in the same order as they are
% presented in mtbf_vec.
VCDF = getVCDF(LQ,sVals,startState,EULERparams,duration,...
    highThreshold,2:length(mtbf_vec)+1);

%% format output
% preallocate results
thisSet = cell(size(mtbf_vec));
thisLB = zeros(size(mtbf_vec));
thisUB = zeros(size(mtbf_vec));

% cycle through each subassembly and trim the outputs to with in the
% thresholds, storing appropriately
for j = 1:length(thisSet)
    % pull out the renewal cdf for this subassembly, with spares numbers
    thisVCDF = [VCDF(:,1) VCDF(:,j+1)];
    
    % grab the section with probabilities between lowThreshold and
    % highThreshold, and store the results in thisSet
    thisSet{j} = thisVCDF(find(thisVCDF(:,2)>=lowThreshold & ...
        thisVCDF(:,2)<=highThreshold),:);
    
    % store upper and lower bounds
    thisLB(j) = thisSet{j}(1,1);
    thisUB(j) = thisSet{j}(end,1);
end