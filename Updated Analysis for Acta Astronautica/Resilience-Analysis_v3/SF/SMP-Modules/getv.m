% getv.m
% Creator: Andrew Owens         Last Updated: 2014-11-24
% Inputs:
%   LQ - cell array of Laplace domain values for the kernel matrix.
%   startState - state the system was in at time t = 0
%   sVals - matrix containing the complex values  at which LT data are
%           desired, in the form s(j) = sVals(j,1) + i*sVals(j,2)
%   renewalStates - states for which the renewal probabilities are desired
%   cutoff - cutoff probability; p <= cutoff redefined as 0
%   EULERparams - vector containing values for m, n, and a to use in
%                 this numerical ILT application. Recommended values are
%                 [11; 15; 18.4].
%   resultTime - time at which result is desired
% Outputs:
%   v - cell array of vectors giving the PMFs of the number of visits to
%       each state. The PMF runs from 0 until the probability of an
%       additional renewal is below the cutoff probability. Entries in the
%       cell array are indexed to correspond to the entries in the
%       renewalStates input
function v = getv(LQ,startState,sVals,renewalStates,cutoff,EULERparams,...
    resultTime)
v = cell(size(renewalStates)); % preallocate v
IDmat = speye(size(LQ{1})); % create sparse identity matrix
oneMat = ones(size(LQ{1})); % create matrix of ones
% calculate LT of first passage time distribution Lg
Lg = cell(size(LQ)); % preallocate Lg
for j = 1:length(LQ)
    Lg{j} = LQ{j}*inv(IDmat - LQ{j})/(IDmat.*inv(IDmat - LQ{j}));
end
% calculate cdf for each state, use to generate pmf
for j = 1:length(renewalStates) % for each state where results are desired
    LV = cell(size(Lg));
    nRenewals = 0; % reset renewal counter
    thisCDF = []; % initialize cdf
    p = 0; % initialize probability flag
    while p <= 1-cutoff % while there is a probability of more renewals
        % calculate LV for this state with this many renewals
        for k = 1:length(LV)
            thisLV = (1/(sVals(k,1) + 1i*sVals(k,2))).*(oneMat - ...
                Lg{k}.*(oneMat*(IDmat.*Lg{k})^nRenewals));
            LV{k} = thisLV(startState,renewalStates(j));
        end
        % use EULER to get time domain cdf probability
        p = EULERmachine(EULERparams,LV,resultTime);
        thisCDF = [thisCDF, p]; % store
        nRenewals = nRenewals + 1;
    end
    thisPMF = diff([0 thisCDF]); % generate pmf from cdf
    v{j} = thisPMF; % store PMF
end