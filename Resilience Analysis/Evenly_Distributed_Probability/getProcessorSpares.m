%
% getProcessorSpares.m
%
% Creator: Andrew Owens
% Last updated: 2014-09-02
%
% This function determines the number of spares required for each
% subassembly in a given processor in order to obtain the required overall
% probability of having enough spares.
%
% Inputs:
%   processorData - matrix of doubles. Each row corresponds to a
%       subassembly; first column counts the number of spares and the
%       second column is the corresponding probability. Values range from
%       the lowest number of spares that yields a probability above
%       lowThreshold to the first number of spares that yields a
%       probability above highThreshold
%   probabilityReq - required probability. Each subassembly must have
%       enough spares to yield this probability
%   cutoff - cutoff probability; any probability below this number will be
%       considered effectively 0
%   duration - time between resupply; spares are provided to account for
%       this amount of operational time
%   dt - discretization size
%
% Outputs:
%   thisSpares - vector indicating the number of spares required for each
%       subassembly in this processor.
%

function [thisSpares, thisProbabilities, thisDowntime] = ...
    getProcessorSpares(mtbf_vec,num_vec,subassembProbability,cutoff,...
    duration,dt)
% set solver parameters
startState = 1; % starting state
EULERparams = [11; 15; 18.4]; % parameters for EULER numerical ILT

% % use num_vec to extend mtbf_vec at the appropriate location - since the
% % entire processor stops every time any internal component fails, have to
% % consider each component seperately
% full_mtbf_vec = [];
% for j = 1:length(num_vec)
%     full_mtbf_vec = [full_mtbf_vec; mtbf_vec(j).*ones(num_vec(j),1)];
% end
% Don't do this yet; just repeat a transition index in the adjacency data
% and use that transition again, otherwise we'll be here forever

% convert mtbfs and duration to days
mtbf_vec = mtbf_vec./24;
duration = duration/24;

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
mttr = 12/24;
sdr = 1/24;
sig = sqrt(log(1+sdr^2/mttr^2)); % repair shape parameter
mu = log(mttr)-(1/2)*sig^2; % repair log-scale parameter
% last entry is the repair distribution
t = 0:dt:mttr+15*sdr; % go out to 15 standard deviations
pdf = (1./(t.*sqrt(2*pi).*sig)).*...
    exp(-(log(t)-mu).^2./(2*sig^2));
pdf(isnan(pdf)) = 0; % remove any NaNs, replace with 0
pdf = pdf(1:find(pdf>=cutoff,1,'last')); % trim the distribution to cutoff
pdf = pdf./(dt*sum(pdf)); % normalize
transitions{end} = [pdf; dt.*cumsum(pdf)]; % generate cdf and store results

% find number of states
nStates = sum(num_vec)+1;

% set adjacency data and form adjacency matrix
% r = [ones(length(mtbf_vec),1); (2:length(mtbf_vec)+1)'];
% c = [(2:length(mtbf_vec)+1)'; ones(length(mtbf_vec),1)];
% vals = [(1:length(mtbf_vec))'; ...
%     (length(mtbf_vec)+1).*ones(length(mtbf_vec),1)];
% adjMat = sparse(r,c,vals);

r = [ones(sum(num_vec),1); (2:sum(num_vec)+1)'];
c = [(2:sum(num_vec)+1)'; ones(sum(num_vec),1)];

% set vals vector with repetition where needed
vals = [];
for j = 1:length(num_vec)
    vals = [vals; j.*ones(num_vec(j),1)];
end
vals = [vals; length(transitions).*ones(sum(num_vec),1)];
adjMat = sparse(r,c,vals);


% setup and solve SMP
[Q,H] = makeKernel(r,c,vals,adjMat,nStates,transitions);
sVals = getLaplacePoints(duration,EULERparams);
LQ = getLT(Q,r,c,sVals,dt); % get LQ
Hindex = unique(r);
LH = getLT(H,Hindex,ones(size(Hindex)),sVals,dt); % get LH
for j = 1:length(LH)
    LH{j} = diag(LH{j});
end

% preallocate results storage
thisFullSpares = zeros(sum(num_vec),1);
thisFullProbabilities = zeros(sum(num_vec),1);

% for each subassembly, solve for the required number of spares
% state 1 is nominal, so start at state 2
for j = 2:nStates
    % set probability p; this will be the trigger for leavning a while loop
    % later on
    p = 0;
    
    % set initial number of spares to 0; we'll add one to this first thing
    nSpares = -1;
    
    while p < subassembProbability
        % add a spare
        nSpares = nSpares + 1;
        
        % find Laplace domain solution
        LV = getLV(LQ,startState,nSpares,sVals,j);
        
        % ILT to time domain to get probability
        p = EULERmachine(EULERparams,LV,duration);
    end
    
    % store results (adjust indexing to account for start in state 2)
    thisFullSpares(j-1) = nSpares;
    thisFullProbabilities(j-1) = p;
end

% combine the spares and probabilities for duplicate components
% Since the duplicate components are identical, they have identical
% characteristics and can be easily combined.
thisSpares = zeros(size(mtbf_vec));
thisProbabilities = zeros(size(mtbf_vec));

% lastIndex gives the index of the last entry for each subassembly
lastIndex = cumsum(num_vec);
for j = 1:length(mtbf_vec)
    thisSpares(j) = thisFullSpares(lastIndex(j))*num_vec(j);
    thisProbabilities(j) = thisFullProbabilities(lastIndex(j))^num_vec(j);
end

% solve for the expected time in the nominal state; the duration minus this
% time is the expected downtime.
E = getE(LQ,LH,sVals,startState,1,EULERparams,duration);
thisDowntime = duration - E;