clear all

removeNan = true;


%% data

dataFolder = 'C:\Users\carpine\Documents\projets\ponts marne\reprise operations 2021\donnees'; % dossier où les fichier .csv sont
dataFileName = 'esbly_1005.mat';
dataFilePath = fullfile(dataFolder, dataFileName);

dataFilePath = choixData();

load(dataFilePath);

disp(startDate);
% T°
[TemperatureTime, TemperatureTemp] = getTemperature(startDate);
figure;
plot(TemperatureTime, TemperatureTemp);
ylabel('Temperature [°C]');

X = X.';
T = T.';


%% tri channels par ordre croissant

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

%% remove channels, complete nan

if false
    I = [10, 11];
%     I = [1:10, 12:14];
    X(I, :) = 0;
end

if false
    for kc = 1:size(X, 1)
        X(kc, isnan(X(kc, :))) = mean(X(kc, :), 'omitnan');
    end
end

%% enlever donnees redondantes (double t à cause du mode transmit/log)


if 1
    dt0 = mean(diff(T));
    T0 = T;
    X0 = X;
    T = nan(size(T));
    X = nan(size(X));
    
    kt = 1;
    kt0 = 1;
    while kt0 <= length(T0)-1
        if abs(T0(kt0) - T0(kt0+1)) < 1e-4 * dt0
            if all(~isnan(X0(:, kt0)))
                X(:, kt) = X0(:, kt0);
            elseif all(~isnan(X0(:, kt0+1)))
                X(:, kt) = X0(:, kt0+1);
            else
                for kc = 1:size(X0, 1)
                    if ~isnan(X0(kc, kt0))
                        X(kc, kt) = X0(kc, kt0);
                    else
                        X(kc, kt) = X0(kc, kt0+1);
                    end
                end
%                 if any(~isnan(X0(:, kt0:kt0+1)), 'all') % debug
%                     disp(X0(:, kt0:kt0+1));
%                 end
%                 if any(~isnan(X0(:, kt0:kt0+1)), 'all') && any(isnan(X0(:, kt0)) & isnan(X0(:, kt0+1))) % debug
%                     disp(X0(:, kt0:kt0+1));
%                 end
            end
            T(kt) = T0(kt0);
            kt0 = kt0+2;
        else
            X(:, kt) = X0(:, kt0);
            T(kt) = T0(kt0);
            kt0 = kt0+1;
        end
        kt = kt+1;
    end
    T = T(1:kt-1);
    X = X(:, 1:kt-1);
end


%% enlever nan debut fin

if removeNan
    Nt0 = floor(size(X, 2)/2);
    for Nt1 = Nt0:-1:1
        if any(isnan(X(:, Nt1)))
            Nt1 = Nt1 + 1;
            break
        end
    end
    for Nt2 = Nt0:size(X, 2)
        if any(isnan(X(:, Nt2)))
            Nt2 = Nt2 - 1;
            break
        end
    end
    fprintf('NaN debut : %.2fs\nNaN fin : %.2fs\n', [T(Nt1) - T(1), T(end) - T(Nt2)]);
    X = X(:, Nt1:Nt2);
    T = T(:, Nt1:Nt2);
    
    T = T - T(1);
end

%% deformee

dimensionsShapes2;

%% plot

fig = figure;
ax = axes(fig);
plts = plot(T, X);
xlabel(ax, 'Time [s]');
ylabel(ax, 'Acceleration [m/s²]');
legend(channelNames);


Q = 10;
NbMaxRidges = 1;
NbMaxParallelRidges = 1;
fmin = 0;
fmax = 10;

WaveletMenu('WaveletPlot', plts, 'Q', Q, 'fmin', fmin, 'fmax', fmax, 'RemoveMean', true,...
    'AutocorrelationMode', true, 'AutocorrelationSVDMode', true, 'AutocorrelationFourierSVDMode', true,...
    'AutocorrelationMaxLag', 5/(2*pi*2.2*0.01), 'AutocorrelationNsvd', 6, 'FourierScale', 'log',...
    'MaxRidges', NbMaxRidges, 'MaxParallelRidges', NbMaxParallelRidges, 'RealShapePlot', shapePlotBridge,...
    'AnimatedShapePlot', shapePlotBridgeAnim);







