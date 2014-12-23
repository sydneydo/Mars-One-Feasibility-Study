%
% spares_required_main.m
%
% Creator: Andrew Owens
% Last updated: 2014-09-04
%
% This script executes theh spares_required_evenDist function with
% parametric input to investigate the effect of different parameters on
% sparing requirements.
%

% add the SMP solver modules to the path
addpath SMP_modules_evenDist

%% Set solution parameters

% Required probability for the entire system
overallProbability = 0.99;

% cutoff probability; probabilities less than this will be considered to be
% effectively 0
cutoff = 1e-7;

% time between resupply missions [h]
duration = 19000;

% discretization size
dt = 0.10;

% define processor sets; processors are comprised of the components in rows
% startRow:endRow as encoded in each row of this matrix
processorSets = [1, 7;  % OGA
    8, 16; % CDRA and ORA
    17, 26; % CCAA x4
    27, 32; % UPA
    33, 47; % WPA
    48, 54; % CRA
    55, 57; % ISRU AP
    58, 62; % ISRU SP
    63, 65; % Pre-Deploy ISRU AP
    66, 70]; % Pre-Deploy ISRU SP
    %71, 71]; % GLS (this must always be the last one)

% encode the number of instances of each processor
numInstances = [1; % OGA
    1; % CDRA and ORA are the same
    4; % CCAA in each cabin
    1; % UPA
    1; % WPA
    1; % CRA
    1; % ISRU AP
    1; % ISRU SP
    1; % Pre-Deploy ISRU AP
    1]; % Pre-Deploy ISRU SP
    %1]; % GLS

% GLS flag; set to 1 if there is a GLS, 0 else
GLSflag = 0;

% Set up and solve SMP for each processor
% Processors are comprised of subassemblies. Since all processors are
% separated by buffers, each can be considered independently. Failure of a
% subassembly within a processor takes the entire processor online until
% the failed subassembly is replaced with a spare, at which point the
% processor is brought back to nominal working condition.

% load component data. Columns are:
%   1) Mass [kg]
%   2) Volume [m^3]
%   3) MTBF [h]
%   4) # in Processor
componentData = csvread('componentData.csv',1,3);

%% Run solver

% range of probabilities to investigate
% probs = [0.9:0.01:0.99 0.999 0.9999];

probs = 0.99;

% range of cutoffs to investigate
cutoffs = [1e-7 1e-8 1e-9 1e-10];

% range of discretization sizes to investigate
dts = [0.025:0.025:0.25];

% range of MTBF multipliers
% mtbf_mult = [1:0.25:2];
mtbf_mult = 2;

% results storage
spares_mat = [];
prob_vec = [];
mass_vec = [];
time_vec = [];
down_vec = [];

for j = 1:length(mtbf_mult)
    % for MTBF sensitivity
    componentData(:,3) = componentData(:,3).*mtbf_mult(j);
    tic
    [trueSpares, totalProb, totalMass, totalDowntime] = ...
        spares_required_evenDist(probs,cutoff,duration,dt,...
        processorSets,numInstances,componentData,GLSflag);
    spares_mat = [spares_mat, trueSpares];
    prob_vec = [prob_vec, totalProb];
%     mass_vec = [mass_vec, totalMass];
    time_vec = [time_vec, toc];
    down_vec = [down_vec, totalDowntime];
end