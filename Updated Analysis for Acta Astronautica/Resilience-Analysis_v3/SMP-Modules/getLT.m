% getLT.m
% Creator: Andrew Owens         Last updated: 2014-08-19
% Inputs:
%   f   -   cell array of vectors encoding functions to be LT'd
%   r,c -   vectors indicating the location of entries in the f cell array
%   sVals - matrix containing the complex values  at which LT data are
%           desired, in the form s(j) = sVals(j,1) + i*sVals(j,2)
% Outputs:
%   Lf - cell array containing the Laplace transforms of f at the points
%        inidcated by sVals. Each entry in the cell array corresponds to a
%        row of sVals.
function Lf = getLT(f,r,c,sVals,dt)
% preallocate cell array to store values at each sVal
Lf = cell(size(sVals,1),1);
parfor j = 1:size(sVals,1) % cycle through each point in sVals
    % extract the sVal
    u = sVals(j,1);
    v = sVals(j,2);
    LV = zeros(size(r));    % preallocate a vector of values    
    for k = 1:length(r)    % cycle through each entry in f
        % extract the vector at this location in f, which is the function
        % sampled at the points 0:dt:dt*(length(funVec)-1)
        funVec = f{r(k),c(k)};
        % generate the vector of alpha values corresponding to the length
        % of this vector
        alpha = 0:dt:dt*(length(funVec)-1);
        % use the alpha vector, u, and v to generate the vectors
        % representing the integrand for the real and imaginary
        % coefficients
        realFunVec = exp(-u.*alpha).*cos(v.*alpha).*funVec;
        imagFunVec = exp(-u.*alpha).*sin(v.*alpha).*funVec;
        % numerically integrate with trapz        
        realCoeff = trapz(alpha,realFunVec);
        imagCoeff = trapz(alpha,imagFunVec);
        % store the value in the LV vector
        LV(k) = realCoeff - 1i*imagCoeff;
    end
    % create a sparse matrix using r,c,LV and store it in the
    % appropriate cell in Lf. Use the size of Lf to pad out the matrix
    Lf{j} = sparse(r,c,LV,size(f,1),size(f,2));
end