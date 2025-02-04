function idsWithin = lookupIdsWithinEquation(equation)

finds = regexp(string(equation), "\<x\(\d+,t[^\)]*\)", "match");
if isempty(finds)
    idsWithin = [ ];
    return
end
finds = replace(finds, "t)", "t+0)");
finds = erase(finds, ["x(", "t", ")"]);
finds = sscanf(join(finds, ","), "%g,");
idsWithin = reshape(finds(1:2:end) + 1i*finds(2:2:end), 1, [ ]);
idsWithin = unique(idsWithin);

end%

