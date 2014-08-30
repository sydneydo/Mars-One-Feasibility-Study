% getLaplacePoints.m
% Creator: Andrew Owens         Last updated: 2014-08-19
% Inputs:
%   resultTime - time at which final results are desired; used to determine
%                which points in the Laplace domain are needed for EULER
%   EULERparams - vector containing values for m, n, and a to use in
%                 this numerical ILT application.
% Outputs:
%   sVals - matrix containing the complex values  at which LT data are
%           desired, in the form s(j) = sVals(j,1) + i*sVals(j,2)
function sVals = getLaplacePoints(resultTime,EULERparams)
% unpack the EULER parameters
m = EULERparams(1);
n = EULERparams(2);
a = EULERparams(3);
u = a/(2*resultTime);
v = zeros(m+n+1,1);
for j = 0:n+m
    v(j+1) = j*pi/resultTime;
end
sVals = [u.*ones(size(v)), v];