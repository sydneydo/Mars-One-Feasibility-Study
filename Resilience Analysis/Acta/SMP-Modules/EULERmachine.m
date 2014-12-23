% EULERmachine.m
% Creator: Andrew Owens         Last Updated: 2014-08-19
% Inputs:
%   EULERparams - vector containing values for m, n, and a to use in
%                 this numerical ILT application. Recommended values are
%                 [11; 15; 18.4].
%   LDvals - cell vector containing Laplace domain data for the function
%            at the points required. Each cell contains the scalar, vector, 
%            or matrix of the data at that point in the Laplace domain.
%   resultTime - time at which result is desired
% Outputs:
%   output - the result in the time domain, given the values in LDvals
function output = EULERmachine(EULERparams, LDvals,resultTime)
% unpack the EULER parameters
m = EULERparams(1);
n = EULERparams(2);
a = EULERparams(3);
% outer summation level
output = zeros(size(LDvals{1})); % preallocate output to 0
for k = 0:m
    % inner summation
    innerSum = zeros(size(LDvals{1}));
    for j = 1:n+k
        innerSum = innerSum + (-1)^j * real(LDvals{j+1});
    end
    output = output + nchoosek(m,k)*2^(-m)*...
        ((exp(a/2)/(2*resultTime))*real(LDvals{1}) + ...
        (exp(a/2)/resultTime)*innerSum);
end