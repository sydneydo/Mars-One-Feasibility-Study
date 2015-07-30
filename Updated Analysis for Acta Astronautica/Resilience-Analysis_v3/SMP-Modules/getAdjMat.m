%
% getAdjMat.m
%
% Creator: Andrew Owens
% Last updated: 2014-12-22
%
% Generates adjacency matrices for one-failure-at-a-time systems.
%

function [rows cols entries adjMat] = getAdjMat(numComponents)
entries = [1:numComponents, (numComponents+1)*ones(1,numComponents)]';
rows = [ones(1,numComponents), 2:numComponents+1]';
cols = [2:numComponents+1, ones(1,numComponents)]';
adjMat = sparse(rows,cols,entries);