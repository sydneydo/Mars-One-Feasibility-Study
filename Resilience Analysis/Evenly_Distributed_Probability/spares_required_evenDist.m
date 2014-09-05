%
% spares_required_evenDist.m
%
% Creator: Andrew Owens
% Last updated: 2014-09-04
%
% This function performs a spares analysis for the Mars One ECLSS; the end
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
% Inputs:
%   overallProbability - the required probability of having enough spares,
%                        at the system level
%   cutoff - cutoff probability level; probabilities below this will be
%            considered to be effectively 0
%   duration - time between resupply [h]
%   dt - discretization size in timescale [d]
%   processorSets - indices for the [start, end] of each processor set in
%                   the component dataset
%   numInstances - vector indicating the number of instances for each
%                  processor in the system
%   componentData - matrix encoding the data for each repairable component
%                   in the system. Columns are, in order, mass [kg], volume
%                   [m^3], MTBF [h], and the number of each component in
%                   that processor.
%
% Outputs:
%   trueSpares - vector indicating the number of spares required for each
%                component
%   totalProb - the resulting overall probability of having enough spares
%   totalMass - the total mass of spares required
%

% SEE IF YOU CAN FIND PACKING MASS/VOLUME FRACTION
% solar cells 3000m^2 (340kW)

function [trueSpares, totalProb, totalMass] = spares_required_evenDist(...
    overallProbability,cutoff,duration,dt,processorSets,numInstances,...
    componentData,GLSflag)

% create mass vector and vector indicating the number of each component
massVector = [];
numVector = [];
for j = 1:size(processorSets,1)
    massVector = [massVector; ...
        componentData(processorSets(j,1):processorSets(j,2),1)];
    numVector = [numVector; ...
        componentData(processorSets(j,1):processorSets(j,2),4)];
end

% create result storage for the number of spares for each subassembly and
% the resulting probability for that number of spares
subassemSpares = [];
subassemProbs = [];

% determine number of subassemblies in system
% remember to add in subassemblies for the processors that have multiple
% instances in the system (CRDA x2, CCAA x4)
nSubassem = 0;
for j = 1:length(numInstances)
    nSubassem = nSubassem + sum(numVector(processorSets(j,1):...
        processorSets(j,2)))*numInstances(j);
end

% calculate probability for each subassembly required to obtain overall
% probability requirement
subassemProbability = overallProbability^(1/nSubassem);

% for each processor (not the growth lights yet)
if GLSflag == 1
    subtract = 1;
else
    subtract = 0;
end

tic
for j = 1:size(processorSets,1)-0
    % give status
    disp(['Calculating for Processor ' num2str(j)])
    
    % set up and solve the SMP to get the number of spares required for
    % this processor to obtain the required probability, as well as the
    % value of that probability and the expected downtime for this
    % processor
    [thisSpares, thisProbabilities, thisDowntime] = getProcessorSpares(...
        componentData(processorSets(j,1):processorSets(j,2),3),...
        numVector(processorSets(j,1):processorSets(j,2)),...
        subassemProbability,cutoff,duration,dt);
    
    % store results
    subassemSpares = [subassemSpares; thisSpares];
    subassemProbs = [subassemProbs; thisProbabilities];
    downtime(j) = thisDowntime;
    
    % give status
    thisTime = toc;
    disp(['     Total Elapsed Time: ' num2str(thisTime)])
end

if GLSflag == 1
    % Growth lights are a large array of identical elements. We can just count
    % the number of renewals for the minimum of the exponential processes.
    % Downtime here has no effect on the rest of the system (because there is
    % no redundant growth system), so we don't need to count it.
    disp('Calculating for GLS')
    
    % find MTBF for the whole array
    mtbf_gls = componentData(end,3);
    mtbf_glsArray = 1/(numVector(end)*(1/mtbf_gls));
    [thisSpares, thisProbabilities, ~] = getProcessorSpares(mtbf_glsArray,1,...
        subassemProbability,cutoff,duration,dt);
    % store results
    subassemSpares = [subassemSpares; thisSpares];
    subassemProbs = [subassemProbs; thisProbabilities];
    downtime(j) = 0;
    
    % give status
    thisTime = toc;
    disp(['     Total Elapsed Time: ' num2str(thisTime)])
end

% calculate total mass and probability, accounting for multiple instances

% calculate true number of spares, as well as probability, taking into
% account multiple instances
trueSpares = zeros(size(subassemSpares));
totalProb = 1;
for j = 1:length(numInstances)
    % true number of spares
    trueSpares(processorSets(j,1):processorSets(j,2)) = ...
        subassemSpares(processorSets(j,1):processorSets(j,2)).* ...
        numInstances(j);
    
    % probability
    thisProb = prod(subassemProbs(processorSets(j,1):processorSets(j,2)));
    totalProb = totalProb*(thisProb^numInstances(j));
end

% calculate total mass
totalMass = massVector'*trueSpares;

% write individual subassembly results to file
% csvwrite('RESULTS.csv',trueSpares);

thisTime = toc;

% display outputs
disp('----- RESULTS -----')
disp(['For overall probability of ' num2str(overallProbability) ':'])
disp(['Total mass of spares: ' num2str(totalMass)])
disp(['Resulting Probability: ' num2str(totalProb)])
disp('Subassembly spares counts have been written to RESULTS.csv')
disp(['     Total Elapsed Time: ' num2str(round((thisTime/60)*100)/100)...
    'minutes'])
disp('-------------------')
end