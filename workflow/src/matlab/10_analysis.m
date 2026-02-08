% 10_analysis.m
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
dataRaw = fullfile(root, 'data', 'raw');
dataProcessed = fullfile(root, 'data', 'processed');
outTables = fullfile(root, 'output', 'tables');
outFigures = fullfile(root, 'output', 'figures');

if ~exist(dataProcessed, 'dir'); mkdir(dataProcessed); end
if ~exist(outTables, 'dir'); mkdir(outTables); end
if ~exist(outFigures, 'dir'); mkdir(outFigures); end

% TODO: load data and run analysis
