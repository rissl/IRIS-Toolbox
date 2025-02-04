function outputDatabank = withEmpty(listOfNames)
% -IRIS Macroeconomic Modeling Toolbox
% -Copyright (c) 2007-2020 IRIS Solutions Team.

persistent parser
if isempty(parser)
    parser = extend.InputParser('databank.withEmpty');
    parser.addRequired('ListOfNames', @(x) ischar(x) || iscellstr(x) || isa(x, 'string'));
    parser.addParameter('AddToDatabank', struct( ), @isstruct);
end
parser.parse(listOfNames);
opt = parser.Options;

if ~iscellstr(listOfNames)
    listOfNames = cellstr(listOfNames);
end

%--------------------------------------------------------------------------

SERIES = Series( );

outputDatabank = opt.AddToDatabank;
for i = 1 : numel(listOfNames)
    outputDatabank.(listOfNames{i}) = SERIES;
end

end%

