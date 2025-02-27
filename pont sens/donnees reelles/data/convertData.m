dataFolder = 'C:\Users\carpine\Documents\projets\article bruno\Pont de Sens (donn�es)\donnees_brutes\24_06_03_Avant resserrage\donn�es'; % dossier o� les fichier .txt sont
saveFolder = 'pont sens\donnees reelles\data'; % dossier o� les fichier .mat vont �tre enregistr�s
extention = '.TXT'; % format de l'extension, peut �tre remplac� par '' si pas d'extension

%% conversion & enregistrement


% recherche des fichiers du dossier
files = dir(dataFolder);
filesNames = cell(size(files));
for ind = 1:length(files)
    filesNames{ind} = files(ind).name;
end

% enregistrement des .txt
k = 1;
for ind = 1:length(filesNames)
    fileName = filesNames{ind};
    
    mName = fileName;
    if length(mName) >= length(extention) && isequal(mName(end+1-length(extention):end), extention)  % reconnaissance des 'name'.txt
        mName = mName(1:end-length(extention));
    else
        continue
    end
    
    disp(['TGV', num2str(k), 'A...']);
    k = k+1;
    
    try
        X = dlmread(fullfile(dataFolder, fileName)); % conversion de 'name'.txt en tableau matlab 'X'
        save([saveFolder, '\', mName], 'X'); % enregistrement
    catch
        warning('problem with variable name');
        continue
    end
end