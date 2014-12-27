% getPandE.m
% Creator: Andrew Owens         Last updated: 2014-11-23
% Inputs:
%   LQ - cell array of values of the Laplace transform of the kernel matrix
%        at the values required for EULER inversion at the given time.
%        Entry LQ{j} corresponds to the value of the Laplace transform at
%        the point indicated by sVals(j,:)
%   LH - cell array of values of the Laplace trasform of the unconditional
%        waiting time density matrix at the values required for EULER
%        inversion.
%   sVals - matrix encoding the complex values s = x + i*y at which the
%           Laplace transform must be calcuated for EULER inversion at the
%           given time. The first column contains x values, the second
%           contains y values.
%   startState - state the system is in at time t = 0
%   EULERparams - vector of parameters for the EULER numerical ILT
%                 algorithm. Entries are [m; n; a]
%   resultTime - time at which probabilities are to be calculated
% Outputs:
%   P - vector of state probabilities, for this startState
%   E - vector of expected time in each state
function [P,E] = getPandE(LQ,LH,sVals,startState,EULERparams,resultTime)
LP = cell(size(LQ)); % preallocate LP
LE = cell(size(LQ)); % preallocate LE
ident = speye(size(LQ{1})); % create a sparse identity matrix 
% calculate the Laplace transform LP and LE
for j = 1:length(LP)
    u = sVals(j,1);
    v = sVals(j,2);
    thisLP = (1/(u+1i*v))*inv(ident-LQ{j})*(ident-LH{j});
    thisLE = (1/(u+1i*v))*thisLP;
    LP{j} = thisLP(startState,:);
    LE{j} = thisLE(startState,:);
end
% use EULER to ILT back to the time domain
P = EULERmachine(EULERparams,LP,resultTime);
E = EULERmachine(EULERparams,LE,resultTime);