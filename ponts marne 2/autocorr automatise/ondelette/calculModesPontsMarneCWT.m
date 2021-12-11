clear all

savePath = 'ponts marne 2\autocorr automatise\ondelette\save';

MotherWavelet = 'cauchy';

% mode
manualMode = 0;
saveResults = 1;
saveResults = saveResults & ~manualMode;

% affichage
pauseModes = 1; % pause entre les modes
plotRidgeExtract = 1;
plotShapes = 1;
plotTemp = 0;

% filtrage passe haut
filtrage = 1;
fc_filtre = 3.5; % freq coupure
fmin_filtrage = 5; % min freq propre avec filtre

bridge = 0;
Kf = 0;

%% data

dataFilePath = choixData(bridge);

load(dataFilePath);

[~, dataFileName] = fileparts(dataFilePath);
disp('~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~');
disp(dataFileName);
disp(startDate);
% T°
if plotTemp
    [TemperatureTime, TemperatureTemp] = getTemperature(startDate);
    figure('Name', dataFileName);
    plot(TemperatureTime, TemperatureTemp);
    ylabel('Temperature [°C]');
end

% mise en forme
X = X.';
T = T.';

[X, T] = removeRedundantData(X, T);

[X, T] = removeNanSignal(X, T);

X = -X; % capteurs vers le bas
X = X - mean(X, 2); % moyenne


% tri channels par ordre croissant
[channelNames, I] = sort(channelNames);
X = X(I, :);
I = 1:length(I);
for kc = 1:length(channelNames) % ch2 à la fin
    if strcmp(channelNames{kc}(end-2:end), 'ch2')
        channelNames = [channelNames(1:kc-1), channelNames(kc+1:end), channelNames(kc)];
        I = [I(1:kc-1), I(kc+1:end), I(kc)];
        break
    end
end
X = X(I, :);

Ttot = T(end) - T(1);
dt = Ttot/(length(T)-1);

% deformees modales
dimensionsShapes2;

%% calcul cwt

% chargement def modales
dimensionsShapes2;

% freqs approx fourier
[Freqs0, Damps0] = getFreqsFour(dataFileName);
Freqs0bis = [0, Freqs0, inf];

% save
Freqs = nan(size(Freqs0));
Damps = nan(size(Damps0));
Shapes = nan(size(X, 1), length(Freqs0));
PbCalculRidge = false(size(Freqs0));
MultipleSV = zeros(size(Freqs0));

% % waitbar
% [initWaitBar, updateWaitBar, closeWaitBar] =...
%     getWaitBar(length(Freqs0), 'windowTitle', 'Extraction',...
%     'progressStringFcn', @(k) sprintf('%d/%d', [k, length(Freqs0)]), 'displayTime', 0);
% initWaitBar();

if isempty(Kf) || (length(Kf) == 1 && Kf == 0)
    Kf = 1:length(Freqs0);
end

Nsvprec = 0; % Nsv precedent

for kf = Kf
    freq0 = Freqs0(kf);
    damp0 = Damps0(kf);
    
    % display
    fprintf('\n~~~~~~ mode %d/%d ~~~~~~\n', [kf length(Freqs0)]);
    fprintf('f= %.2f Hz, z = %.2f %%\n', [freq0, 100*damp0]);
    
    Df = sort(abs(Freqs0bis - freq0));
    Df = Df(2);
    ct = 3;
    cf = 5;
    Qmin =  getBoundsQ2(freq0, Df, 0, [0 0], [0 0], ct, ct, cf, MotherWavelet);
    
    % gestion cas modes proches
    if Qmin > 100
        Df = sort(abs(Freqs0bis - freq0));
        Df = Df(3);
        Qmin =  getBoundsQ2(freq0, Df, 0, [0 0], [0 0], ct, ct, cf, MotherWavelet);
        Nsv = 2;
        fprintf(2, 'utilisation plusieur SV ');
    else
        Nsv = 1;
    end
    
    poleMode = 2i*pi*freq0 - 2*pi*damp0*freq0/sqrt(1-damp0^2);
    alphap = sqrt((-4/real(poleMode) + 2/abs(imag(poleMode)))/Ttot);
    Tmaxridge = log(alphap)/real(poleMode);
    
    % filtrage
    if filtrage && freq0 > fmin_filtrage
        Xfiltr = butterworthFilter(T, X, fc_filtre, 'high', 10);
        fprintf('filtrage (fc = %.2fHz)\n', fc_filtre);
    else
        Xfiltr = X;
    end
    
    fmin = freq0-Df/2;
    fmax = freq0+Df/2;
    NbFreqs = 100;
    
    if strcmp(dataFileName, 'changis_0705_1') && kf <= 2
        fmax = 2.2;
    end
    
    if manualMode
        fig = figure;
        plt = plot(T, Xfiltr);
        WaveletMenu('WaveletPlot', plt, 'fmin', fmin, 'fmax', fmax, 'Q', Qmin, 'XLimRidge', [0, Tmaxridge],...
            'AutocorrelationMode', true, 'AutocorrelationSVDMode', true, 'AutocorrelationFourierSVDMode', true,...
            'AutocorrelationMaxLag', 2*Tmaxridge, 'AutocorrelationNsvd', Nsv, 'FourierScale', 'lin',...
            'MaxRidges', 1, 'MaxParallelRidges', inf, 'RealShapePlot', shapePlotBridge,...
            'AnimatedShapePlot', shapePlotBridgeAnim, 'MotherWavelet', MotherWavelet);
        waitfor(fig);
        break
    end
    
    % calcul cross-corr
    Rx = crossCorrelation(Xfiltr, round(2*Tmaxridge/dt), 'unbiased');
    tRx = dt * (0:size(Rx, 3)-1);
    
    % calcul CWT
    [SVrx, SVvectrx] = svdCWT(tRx, Rx, linspace(fmin, fmax, NbFreqs), Qmin, Nsv,...
        'MotherWavelet', MotherWavelet);
    
    Nextractions = 2;
    Tmaxridge0 = Tmaxridge;
    for K = 1:Nextractions % répétition extractions ridges
        for K2 = 1:2
            % calcul ridge
            [t_r, freqs_r, shapes_r, amplitudes_r] = getModesCrossCorr(tRx, SVrx, SVvectrx,...
                Qmin, fmin, fmax, NbFreqs, Nsv, 'NbMaxRidges', 1, 'NbMaxParallelRidges', inf,...
                'XLimRidge', [0, Tmaxridge], 'MotherWavelet', MotherWavelet, 'StopWhenIncreasing', true);
            
            % cas SV2 pour deux premières freqs
            if Nsv == 2
                if isempty(t_r{2}) || (~isempty(t_r{1}) && ~isempty(t_r{2})...
                        && abs(mean(freqs_r{1}{1}) - freq0) < abs(mean(freqs_r{2}{1}) - freq0))
                    Nsv = 1;
                end
                if Nsvprec == 1
                    Nsv = 2;
                elseif Nsvprec == 2
                    Nsv = 1;
                end
                MultipleSV(kf) = Nsv;
                
                fprintf('-> SV%d\n', Nsv);
            end
            
            if K2 == 1 && Tmaxridge > Tmaxridge0 && (isempty(t_r{Nsv}) || abs(t_r{Nsv}{1}(end) - Tmaxridge) > 3*dt)
                % calcul cross-corr
                Rx = crossCorrelation(Xfiltr, round(2*Tmaxridge/dt), 'unbiased');
                tRx = dt * (0:size(Rx, 3)-1);
                
                % calcul CWT
                [SVrx, SVvectrx] = svdCWT(tRx, Rx, linspace(fmin, fmax, NbFreqs), Qmin, Nsv,...
                    'MotherWavelet', MotherWavelet);
            else
                break
            end
        end
        
        % cas pas de ridge
        if isempty(t_r{Nsv})
            warning('problème extraction ridge');
            PbCalculRidge(kf) = true;
            freq0 = nan;
            damp0 = nan;
            shape_moy = nan(size(X, 1), 1);
            break
        end
        
        % conversion
        t_r = t_r{Nsv}{1};
        freqs_r = freqs_r{Nsv}{1};
        shapes_r = shapes_r{Nsv}{1};
        amplitudes_r = amplitudes_r{Nsv}{1};
        
        % cas d'aret du ridge avant la limite
        if abs(t_r(end) - Tmaxridge) > 3*dt
            warning('arrêt ridge avant borne');
            PbCalculRidge(kf) = true;
        end
        
        % calcul moyennes
        shape_moy = mean(shapes_r, 2);
        shape_moy = shape_moy * sign(real(shape_moy(8))); %orientation
        freq_moy = mean(freqs_r);
        coeffsRegLin = log(amplitudes_r) / [ones(size(t_r)); t_r];
        lambda_reg = coeffsRegLin(2);
        
        
        % pole mode
        poleMode = 2i*pi*freq_moy + lambda_reg;
        alphap = sqrt((-4/real(poleMode) + 2/abs(imag(poleMode)))/Ttot);
        if K < Nextractions
            Tmaxridge = log(alphap)/real(poleMode);
        end
        
        % parametres modaux
        freq0 = abs(poleMode) / (2*pi);
        damp0 = -real(poleMode) / abs(poleMode);
        
        % print
        if K == Nextractions
            fprintf('damped frequency: %.10f Hz\ndecay rate: %.10f Hz\n-> natural frequency: %.10f Hz\n-> damping ratio: %.10f %%\n',...
                [freq_moy, lambda_reg, freq0, 100*damp0]);
        end
    end
    Nsvprec = Nsv;
    
    % save
    Freqs(kf) = freq0;
    Damps(kf) = damp0;
    Shapes(:, kf) = shape_moy;
    
    if plotRidgeExtract
        % freq
        fig = figure;
        fig.Position(1) = fig.Position(1) - fig.Position(3)/2;
        plot(t_r, freqs_r);
        yline(freq_moy, '--r');
        xline(Tmaxridge);
        set(gca, 'ylim', freq_moy*(1 + 0.1*[-1 1]));
        % damp
        fig = figure;
        fig.Position(1) = fig.Position(1) + fig.Position(3)/2;
        plot(t_r, amplitudes_r);
        hold on
        plot(t_r, exp(coeffsRegLin * [ones(size(t_r)); t_r]), '--r');
        xline(Tmaxridge);
        set(gca, 'yscale', 'log');
        set(gca, 'ygrid', 'on');
    end
    
    if plotShapes
        figName = sprintf('f = %.2fHz, z = %.2f%%, I = %.2f %%', [freq0, 100*damp0, 100*nonPropIndex(shape_moy)]);
        fig = shapePlotBridge(real(shape_moy), figName);
        fig.Position(1) = fig.Position(1) - fig.Position(3)/2;
        fig.Position(2) = fig.Position(2) - fig.Position(4) - 10;
        
%         fig = shapePlotBridgeAnim(shape_moy, figName);
%         fig.Position(1) = fig.Position(1) + fig.Position(3)/2;
%         fig.Position(2) = fig.Position(2) - fig.Position(4) - 10;
    end
    
%     updateWaitBar();
    
    if pauseModes
        inputStr = input('continue? ', 's');
        if strcmp(inputStr, 'inv') || strcmp(inputStr, 'inverse')
            Shapes(:, kf) = -Shapes(:, kf);
        end
        close all
    end
end
% closeWaitBar();


if saveResults
    saveFile = fullfile(savePath, ['modes_', dataFileName]);
    save(saveFile, 'Freqs', 'Damps', 'Shapes', 'PbCalculRidge', 'MultipleSV');
    disp('saved');
end



















