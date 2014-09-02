% getLV.m
% Creator: Andrew Owens         Last updated: 2014-08-19
% Inputs:
%   LQ - cell array of Laplace domain values for the kernel matrix.
%   startState - state the system was in at time t = 0
%   nRenewals - number of renewals to calculate probabilities for
%   sVals - matrix containing the complex values  at which LT data are
%           desired, in the form s(j) = sVals(j,1) + i*sVals(j,2)
%   renewalStates - states for which the renewal probabilities are desired
% Outputs:
%   LV - cell array of Laplace domain values for the Markov renewal
%        probabilities
function LV = getLV(LQ,startState,nRenewals,sVals,renewalStates)
LV = cell(size(LQ)); % preallocate LV
IDmat = speye(size(LQ{1})); % create a sparse identity matrix
oneMat = ones(size(LQ{1})); % create matrix of ones
for j = 1:length(LV)
    u = sVals(j,1);
    v = sVals(j,2);
    % calculate g
    g = LQ{j}*inv(IDmat - LQ{j})/(IDmat.*inv(IDmat - LQ{j}));
    % calculate LV
    thisLV = (1/(u+1i*v))*(oneMat-g.*(oneMat*(IDmat.*g)^nRenewals));
    LV{j} = thisLV(startState,renewalStates); % store the results
end