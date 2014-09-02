%
% probabilityConstraint.m
%
% Creator: Andrew Owens
% Last updated: 2014-09-01
%
% This function handles the nonlinear constraint in the optimization: the
% probability must be greater than lowThreshold, or
%
%                   lowThreshold - p <= 0
%
% Inputs:
%   x - the design vector; in this case a vector indicating the number of
%       spares supplied for each subassembly
%
% Outputs:
%   c - the value of the constraint
%   ceq - value for equality constraints (unused, since no equality
%         constraints are allowed in integer optimization with ga
%

function [c, ceq] = probabilityConstraint(x)
ceq = [];

lowThreshold = 0.99;

% Read the spares data. This is a cell array; each cell corresponds to a
% subassembly, and contains a matrix giving the probability (second column)
% corresponding to a given number of spares (first column).
sparesData = load('sparesData.mat');

% calculate the overall probability of having enough spares, p

% set p
p = 1;

% iterate through each subassembly
for j = 1:length(x)
    % isolate this component
    thisData = sparesData.sparesData{j};
    
    % find the probability based on the design vector entry
    thisP = thisData(find(thisData(:,1)==ceil(x(j))),2);
    
    if length(thisP) > 1
        disp('Something wrong here')
    end
    
    % multiply the overall probability by this value
    p = p*thisP;
end

% calculate the constraint
c = lowThreshold - p;

% keyboard