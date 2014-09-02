% getVCDF.m
% Creator: Andrew Owens         Last updated: 2014-08-19
% Inputs:
%   LQ - cell array of values of the Laplace transform of the kernel matrix
%        at the values required for EULER inversion at the given time.
%        Entry LQ{j} corresponds to the value of the Laplace transform at
%        the point indicated by sVals(j,:)
%   sVals - matrix encoding the complex values s = x + i*y at which the
%           Laplace transform must be calcuated for EULER inversion at the
%           given time. The first column contains x values, the second
%           contains y values.
%   startState - state the system is in at time t = 0
%   EULERparams - vector of parameters for the EULER numerical ILT
%                 algorithm. Entries are [m; n; a]
%   resultTime - time at which probabilities are to be calculated
%   renewalThreshold - threshold value for renewal CDF calculation.
%   renewalStates - states for which the renewal probabilities are desired
% Outputs:
%   VCDF - matrix containing the CDFs for each renewal probability. Each
%          row corresponds to a given number of renewals, starting at 0.
%          Column 1 indicates the number of renewals, and each subsequent
%          column contains the Markov renewal probability CDF for the
%          states indicated in renewalStates, in order. Probabilities are
%          calculated until the lowest probability reaches
%          rewnewalThreshold or 100 spares are utilized, whichever happens
%          first.
function VCDF = getVCDF(LQ,sVals,startState,EULERparams,resultTime,...
    renewThreshold,renewalStates)
% preset the trigger p, which will be the minimum of the renewal
% probabilities of the states to watch
p = 0;
nSpares = 0; % set initial number of spares to 0
VCDF = []; % preallocate VCDF matrix
% Calculate renewal probabilities in a while loop until the minimum
% probability is above the threshold or 1000 spares are used. If 1000
% spares are used a warning is displayed.
while p <= renewThreshold && nSpares < 1001
    LV = getLV(LQ,startState,nSpares,sVals,renewalStates);  % calculate LV    
    V = EULERmachine(EULERparams,LV,resultTime); % find probabilities
    VCDF = [VCDF; nSpares, V];% store probabilities and number of spares
    nSpares = nSpares + 1;  % update the number of spares
    p = min(V);  % check the trigger
end
% display warning for 1000 spares
if nSpares >= 1000
    disp('WARNING: Spares calculations cut off at 1000 spares')
end