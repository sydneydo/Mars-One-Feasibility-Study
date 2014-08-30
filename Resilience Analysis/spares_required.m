%
% spares_required.m
%
% Creator: Andrew Owens
% Last updated: 2014-08-28
%
% This script performs a spares analysis for the Mars One ECLSS; the end
% result is the minimum mass of spares required (per crew of 4) to ensure a
% probability greater than a given threshold value that enough spares are
% supplied to implement any required repairs before the next resupply in
% two years.
%
% The implemented methodology is based on the semi-Markov analysis
% techniques described in
%   Owens, A. C., 'Quantitative Probabilistic Modeling of Environmental
%       Control and Life Support System Resilience for Long-Duration Human
%       Spaceflight,' S.M. Thesis, Massachusetts Institute of Technology,
%       2014.
%
% Assumptions:
%   1) Buffers are sized to be sufficiently large to isolate failures (i.e.
%      failed components are repaired before the buffers they manage
%      deplete)
%   2) Repair is implemented via replacement of the failed component with
%      an identical spare, which returns the system to good-as-new
%   3) Components exhibit exponential failure distributions (constant
%      failure rate)
%

addpath SMP_modules

%% Set solution parameters

% minimum allowable probability; this is the probability that the minimum
% mass architecture will be calculated for
lowThreshold = 0.95;

% maximum probability; probabilities above this number will be considered
% to be effectively 1
highThreshold = 1 - 1e-8;

% time between resupply missions [h]
duration = 2*365*24;

%% Set up and solve SMP for each processor
% Processors are comprised of subassemblies. Since all processors are
% separated by buffers, each can be considered independently. Failure of a
% subassembly within a processor takes the entire processor online until
% the failed subassembly is replaced with a spare, at which point the
% processor is brought back to nominal working condition.

% load component data
% col 1 is mass [kg], col 2 is MTBF [h]
componentData = csvread('componentData.csv',0,1);

% define processor sets; processors are comprised of the components in rows
% startRow:endRow as encoded in each row of this matrix
processorSets = [1, 7;  % OGA
    8, 16; % CDRA
    17, 25; % ORA (if it exists, else comment this line out)
    26, 35; % CCAA
    36, 42; % UPA
    43, 58; % WPA
    59, 65; % CRA
    66, 66]; % GLS

% create result storage
% This will be a cell array of matrices, with each cell corresponding to a
% subassembly
% Frist row is a number of spares
% Second row is the probability that that many spares is enough
sparesData = {};

% storage for lower and upper bounds
lowerBound = [];
upperBound = [];

% for each processor
for j = 1:length(processorSets)
    % set up and solve the SMP to get the number of spares and probability
    % for this processor
    [thisSet thisLB thisUB] = getProcessorSparesData(...
        componentData(processorSets(j,1):processorSets(j,2),:),...
        lowThreshold, highThreshold, duration);
    
    % store results
    sparesData = [sparesData; thisSet];
    
    % store lower bound and upper bound for these elements
    lowerBound = [lowerBound; thisLB];
    upperBound = [upperBound; thisUB];
end

%% Optimization
% Find the minimum mass architecture that provides an overall probability
% of success greater than the lowThreshold given above

% save sparesData to a .mat file; it will be called in the objective
% function of the optimization
save('sparesData.mat','sparesData');

% set inputs to optimization
% in each of these, the design vector x is the number of spares for each
% processor

% fitness function; outputs mass of the number of spares used
fitnessfcn = @(x) x.*massVector;

% number of variables
nvars = length(sparesData);

% lower bound, upper bound
lb = lowerBound;
ub = upperBound;

% Contstraint: probability >= lowThreshold
% In this case the constraint is nonlinear, so A and b don't matter. The
% optimizer calls a constraint function, probabilityConstraint. User must
% ensure that lowThreshold is appropriately updated in that file.

% integer constraints: all design variables are integers
IntCon = 1:nvars;

% ga options (for details see
% http://www.mathworks.com/help/gads/genetic-algorithm-options.html)
options = gaoptimset('PlotFcns',@gaplotbestf);


[x,fval,exitflag] = ga(fitnessfcn,nvars,[],[],[],[],lb,ub,nonlcon,...
    IntCon,options);


