% getTotalMassPMF.m
% Creator: Andrew Owens         Last updated: 2014-11-24
% Inputs:
%   pmfs - cell array of pmfs for the number of spares required for each
%          individual component in the system
%   masses - vector indicating the mass of each individual component;
%            indices correspond to the indices of pmfs
%   dm - discretization level of mass; indices in the final pmf will
%        indicate the mass value (i-1)*dt
% Outputs:
%   totalMassPMF - pmf of the total mass
function totalMassPMF = getTotalMassPMF(pmfs,masses,dm)
% transform the spares number pmfs for each component in to mass pmfs on
% the discrete space defined by dm, and convolve the mass pmfs together as
% you go to develop the total mass pmf
totalMassPMF = 1; % initialize
for j = 1:length(pmfs)
    % generate a vector of masses corresponding to the number of spares
    % required
    massVec = (0:length(pmfs{j})-1).*masses(j);
    % transform into indices on the discrete space, rounding up where
    % needed
    indices = ceil(massVec./dm);
    % if the mass of the component is less than dm, there will be repeat
    % indices; therefore need to go through more complicated method for
    % generating final pmf
    if masses(j) < dm
        thisPMF = zeros(1,max(indices)+1);
        for k = 0:max(indices)
            thisPMF(k+1) = sum(pmfs{j}(indices==k));
        end
    else
        thisPMF = full(sparse(1,indices+1,pmfs{j}));
    end
    totalMassPMF = conv(totalMassPMF,thisPMF);
end