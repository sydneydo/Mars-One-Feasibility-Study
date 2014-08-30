% makeKernel.m
% Creator: Andrew Owens         Last updated: 2014-08-19
% Inputs:
%   r,c,vals - row, column, and value data for entries in the adjacency
%              matrix (aka the result of a find() command)
%   nStates - number of states in the system
%   pdfs - PDFs for this system, as a cell array of symbolic functions.
%          Each entry corresponds to a value in vals.
%   cdfs - CDFs for this system, as a cell array of symbolic functions.
%          Each entry corresponds to a value in vals.
% Outputs:
%   Q - kernel matrix (cell array of vectors)
%   H - unconditional waiting time density matrix (cell array of vectors)
function [Q,H] = makeKernel(r,c,vals,adjMat,nStates,transitions)
Q = cell(nStates); % preallocate
H = cell(nStates,1);
Q_vec = cell(size(vals)); % preallocate vector to store Q entries
for j = 1:length(vals) % for each entry
    entry = transitions{vals(j)}(1,:);     % grab the pdf vector
    colsInThisRow = c(r==r(j)); % Find the column indices for this row
    % find the other columns (take out the current column)
    % this is a vector of the column indices of the CDFs that need to be
    % multiplied together (1-F(t))
    otherCols = colsInThisRow(colsInThisRow~=c(j));
    % if others is empty, return only the PDF (it would be multiplied by 1
    % over and over). Otherwise, multiply by 1-CDF for each CDF in others
    if ~isempty(otherCols)
        % to find the entries at these locations, use the adjacency matrix
        otherVals = adjMat(r(j),otherCols);
        for k = 1:length(otherVals)
            % here we have to do some length matching. Only have to keep
            % the shortest length present, because the vectors are
            % truncated to eliminate negligible values. Points beyond the
            % vector are effectively 0.
            len = min(length(entry),length(transitions{otherVals(k)}(2,:)));
            entry = entry(1:len).*(1-transitions{otherVals(k)}(2,1:len));
        end
    end
    Q_vec{j} = entry;     % store the entry
end
for j = 1:length(r) % using the r, c, and Q_vec data, create the Q matrix
    Q{r(j),c(j)} = Q_vec{j};
end
% go through each row that has entries in Q and add all the entries
% together to form the entry for H
uniqueRows = unique(r);
for j = 1:length(uniqueRows)
    thisH = 0;
    colsToAdd = c(r==uniqueRows(j));
    for k = 1:length(colsToAdd)
        % here we also have to do some length adjustment - but we need to
        % keep length. Pad the shorter vector with zeros on the end to be
        % the same length as the longer vector
        len = max(length(thisH),length(Q{j,colsToAdd(k)}));
        thisH = [thisH, zeros(1,len-length(thisH))] + ...
            [Q{j,colsToAdd(k)}, zeros(1,len-length(Q{j,colsToAdd(k)}))];
    end
    H{j} = thisH;
end