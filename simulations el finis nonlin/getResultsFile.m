function filePath = getResultsFile(fileNb)

dataFolder = 'simulations el finis nonlin\resultats';

% last simulation
if nargin == 0
    listing = dir(dataFolder);
    listingNames = {listing.name};
    nbSimul = 0;
    for kname = 1:length(listingNames)
        name1 = strsplit(listingNames{kname}, '_');
        name1 = name1{1};
        if length(name1) > 5 && strcmp(name1(1:5), 'simul')
            nbSimul = max(nbSimul, str2double(name1(6:end)));
        end
    end
    fileNb = nbSimul;
end

% data download
listing = dir(dataFolder);
listingNames = {listing.name};
simul_name = '';
for kname = 1:length(listingNames)
    name1 = strsplit(listingNames{kname}, '_');
    name1 = name1{1};
    if length(name1) > 5 && strcmp(name1(1:5), 'simul') && str2double(name1(6:end)) == fileNb
        simul_name = listingNames{kname};
        break
    end
end
if isempty(simul_name)
    error('file not found');
end

filePath = fullfile(dataFolder, simul_name);

end
