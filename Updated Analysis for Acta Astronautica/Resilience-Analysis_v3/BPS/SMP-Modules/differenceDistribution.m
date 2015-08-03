% difference_distribution.m
% Creator: Andrew Owens         Last updated: 2014-08-19
% Inputs:
%   X - vector of sample points of the pdf f_x(x). The first entry
%       corresponds to x = 0, and the rest are evenly spaced with spacing
%       dt. The range of x is from 0 until a negligible tail can be
%       truncated.
%   Y - vector of sample points of the pdf f_y(y). The first entry
%       corresponds to y = 0, and the rest are evenly spaced with spacing
%       dt. The range of y is from 0 until a negligible tail can be
%       truncated.
%   dt - spacing of sample points.
%   cutoff - cutoff point for negligible tails. values lower than this will
%            be trimmed out of the final distribution.
% Outputs:
%   Z - vector of sample points of the pdf f_z(z), which is the
%       distribution of the difference X - Y when z>=0. The first entry
%       corresponds to z = 0, and the rest are evenly spaced with a spacing
%       of dt. The range of z is from 0 until a negligible tail can be
%       truncated.
function Z = differenceDistribution(X,Y,dt,cutoff)
% pad the end of the shorter vector with zeros to make them the same length
% if they're the same length don't do anything
if length(X) < length(Y)
    X = [X, zeros(1,length(Y)-length(X))];
elseif length(Y) < length(X)
    Y = [Y, zeros(1,length(X)-length(Y))];
end
% pad the front of each one so that it is centered on 0, and flip Y to
% create Y_
padX = [zeros(1,length(X)-1), X];
npadY = fliplr([zeros(1,length(Y)-1), Y]);
% convolve the padded X distribution with Y_ to obtain the difference
% distribution D = X - Y
% the center index of this vector corresponds to 0
fullZ = dt*conv(padX,npadY,'same');
% find the index for z = 0
zero_index = (length(fullZ)+1)/2;
% find the last index before the cutoff tail
cutoff_index = find(fullZ>=cutoff,1,'last');
% if the cutoff is before 0, then effectively the distribution is 0.
% Returning that doesn't work for the rest of the calculations, so model it
% as an impulse at dt (the first index after zero). Effectively, in the
% remote chance that the previous transition occurs, the next one will
% occur immediately
if cutoff_index <= zero_index
    Z = [0 1];
else
    % truncate the distribution at 0 and take the upper half. Scale this
    % appropriately (ie divide by 1-cdf up to 0)
    Zlong = fullZ(zero_index:end)./(1-dt*sum(fullZ(1:zero_index-1)));
    % trim off negligible tail (beyond 1e-10)
    Z = Zlong(1:find(Zlong>=cutoff,1,'last'));
end