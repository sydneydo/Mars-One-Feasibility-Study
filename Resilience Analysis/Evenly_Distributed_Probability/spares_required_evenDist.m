%
% spares_required_evenDist.m
%
% Creator: Andrew Owens
% Last updated: 2014-09-02
%
% This script performs a spares analysis for the Mars One ECLSS; the end
% result is the mass of spares required to obtain the minimum probability
% input in the solution parameters section.
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

% add the SMP solver modules to the path
addpath SMP_modules_evenDist

%% Set solution parameters

% minimum allowable probability
lowThreshold = 0.99;

% cutoff probability; probabilities less than this will be considered to be
% effectively 0
cutoff = 1e-8;

% time between resupply missions [h]
duration = 2*365*24;

% discretization size
dt = 0.05;

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

% create mass vector
for j = 1:size(processorSets,1)
    massVector = [massVector; ...
        componentData(processorSets(j,1):processorSets(j,2),1)];
end

% create result storage for the number of spares for each subassembly
nSpares = zeros(size(massVector));

% for each processor
tic
for j = 1:size(processorSets,1)
    % give status
    disp(['Calculating for Processor ' num2str(j)])
    
    % set up and solve the SMP to get the number of spares and probability
    % for this processor
    [thisSet, thisLB, thisUB] = getProcessorSparesData_evenDist(...
        componentData(processorSets(j,1):processorSets(j,2),2),...
        lowThreshold, cutoff, highThreshold, duration, dt);
    
    % store results
    nSpares(j) = thisSpares;
    
    % give status
    thisTime = toc;
    disp(['     Total Elapsed Time: ' num2str(thisTime)])
end

%% Optimization
% Find the minimum mass architecture that provides an overall probability
% of success greater than the lowThreshold given above

% save sparesData to a .mat file; it will be called in the constraint
% function of the optimization
save('sparesData.mat','sparesData');

% set inputs to optimization
% in each of these, the design vector x is the number of spares for each
% processor

% fitness function; outputs mass of the number of spares used
fitnessfcn = @(x) x*ceil(massVector);

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
options = gaoptimset('PlotFcns',@gaplotbestf,'TolFun',1e-20,...
    'StallGenLimit',300,'PopulationSize',20*66);

disp('Performing Optimization')
[x,fval,exitflag] = ga(fitnessfcn,nvars,[],[],[],[],lb,ub,...
    @probabilityConstraint,IntCon,options);
thisTime = toc;
disp(['     Total Elapsed Time: ' num2str(thisTime)])