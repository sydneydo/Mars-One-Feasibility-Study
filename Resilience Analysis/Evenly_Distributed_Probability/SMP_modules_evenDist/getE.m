% getE.m
% Creator: Andrew Owens         Last updated: 2014-09-03
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
%   desiredStates - states for which expected time is desired
%   EULERparams - vector of parameters for the EULER numerical ILT
%                 algorithm. Entries are [m; n; a]
%   resultTime - time at which probabilities are to be calculated
% Outputs:
%   E - vector of the expected time in each state, for this startState
function E = getE(LQ,LH,sVals,startState,desiredStates,EULERparams,...
    resultTime)
LE = cell(size(LQ)); % preallocate LE
ident = speye(size(LQ{1})); % create a sparse identity matrix 
% calculate the Laplace transform LE
for j = 1:length(LE)
    u = sVals(j,1);
    v = sVals(j,2);
    thisLE = ((1/(u+1i*v))^2)*inv(ident-LQ{j})*(ident-LH{j});
    LE{j} = thisLE(startState,desiredStates);
end
% use EULER to ILT back to the time domain
E = EULERmachine(EULERparams,LE,resultTime);