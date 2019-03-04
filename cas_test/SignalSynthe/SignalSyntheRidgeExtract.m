%% Clear
clear
close all
%% Infos
% Signal Y fonction de X de la forme
% Y = sin(2 * pi * f0 * X) * exp(- xi0 * 2 * pi * f0 * X)

%% Param�tres du signal synth�tique

f0 = 13 ; % Fr�quence du signal synthe
xi0 = .02 ; % " taux d'amortissement " du signal synthe

Fs = 1000; % Fr�quence d'�chantillonnage du signal

%% Param�tres d'extraction

Q =             20 ; % Facteur de qualit�
f_min =         5 ; % freq. min de la plage freq. de calcul
f_max =         25; % freq. max de la plage freq. de calcul
nb_freq =       200 ; % Nb de freq. discr�tis�es sur la plage freq.

NbMaxRidges = 1 ; % Nb max. de ridges � chercher
LengthMinRidge = 0; % Longueur min. des ridges � chercher
MinModu = 0; % Module minimum d'un ridge identifi�

%% Creation signal synth�tique

X=0:1/Fs:10-1/Fs; % Vecteur temps
Y = exp(-xi0*2*pi.*f0.*X).*sin(2*pi*f0.*X); % Signal

%% Trac� de la CWT avec les param�tres retenus pour l'identification

WvltPlot(X,Y,linspace(f_min,f_max,nb_freq),Q,'PlotScale','abs')

%% ridge extract

ridge = RidgeExtract(X,Y,Q,f_min,f_max,nb_freq,...
    'NbMaxRidges',NbMaxRidges,'MinModu',MinModu,'LengthMinRidge',LengthMinRidge); % Appel � la fonction d'extraction
n_ridge=length(ridge.time); % On compte le nb. de ridges effectivement retenus

%%
figure
%% plot ridges freq
% On trace la fr�quence du/des ridge(s) identifi�(s)
% En trait plein, la partie du ridge hors zone estim�e des effets de bord
% En pointill�s, la partie du ridge dans la zone estim�e des effets de bord

subplot(2,2,1)
hold on
ax=gca;

for C_r=1:n_ridge
    h=plot(ridge.time{C_r},ridge.freq{C_r},...
        'LineWidth',1.5,'DisplayName',sprintf('Test signal, ridge %d',C_r));
    plot(ridge.time{C_r},ridge.freqraw{C_r},...
        'Color',get(h,'Color'),'LineStyle',':','HandleVisibility','off','LineWidth',1)
    ax.ColorOrderIndex=mod(ax.ColorOrderIndex-2,7)+1;
end

xlabel('time [s]')
ylabel('f(ridge) [Hz]')
axis([-inf,+inf,f_min,f_max]);
hold off

%% plot ridges abs
% On trace l'amplitude A du/des ridge(s) identifi�(s)
% En trait plein, la partie du ridge hors zone estim�e des effets de bord
% En pointill�s, la partie du ridge dans la zone estim�e des effets de bord

subplot(2,2,2)
hold on
ax=gca;

for C_r=1:n_ridge
    h=plot(ridge.time{C_r},log(abs(ridge.val{C_r})),...
        'LineWidth',1.5,'DisplayName',sprintf('Test signal, ridge %d',C_r));
    plot(ridge.time{C_r},log(abs(ridge.valraw{C_r})),...
        'Color',get(h,'Color'),'LineStyle',':','HandleVisibility','off','LineWidth',1)
    ax.ColorOrderIndex=mod(ax.ColorOrderIndex-2,7)+1;
end

xlabel('time [s]')
ylabel('log|CWT(ridge)|')
hold off

%% plot amor
% On trace -A'/(2 pi A f) du/des ridge(s) identifi�(s)
% En trait plein, la partie du ridge hors zone estim�e des effets de bord
% En pointill�s, la partie du ridge dans la zone estim�e des effets de bord

subplot(2,2,3)
hold on
ax=gca;

for C_r=1:n_ridge
    h=plot(ridge.time{C_r},ridge.inv2Q{C_r},...
        'LineWidth',1.5,'DisplayName',sprintf('Test signal, ridge %d',C_r));
    plot(ridge.time{C_r},ridge.inv2Qraw{C_r},...
        'Color',get(h,'Color'),'LineStyle',':','HandleVisibility','off','LineWidth',1)
    ax.ColorOrderIndex=mod(ax.ColorOrderIndex-2,7)+1;
end

xlabel('time [s]')
ylabel('-diff log|CWT(ridge)|/(2\pif(ridge)) [1]')
axis([-inf,+inf,0,.05]);
hold off

%% plot diff
% On trace -A'/(2 pi A) du/des ridge(s) identifi�(s)
% En trait plein, la partie du ridge hors zone estim�e des effets de bord
% En pointill�s, la partie du ridge dans la zone estim�e des effets de bord

subplot(2,2,4)
hold on
ax=gca;

for C_r=1:n_ridge
    h=plot(ridge.time{C_r},ridge.bandwidth{C_r},...
        'LineWidth',1.5,'DisplayName',sprintf('Test signal, ridge %d',C_r));
    plot(ridge.time{C_r},ridge.bandwidthraw{C_r},...
        'Color',get(h,'Color'),'LineStyle',':','HandleVisibility','off','LineWidth',1)
    ax.ColorOrderIndex=mod(ax.ColorOrderIndex-2,7)+1;
end

xlabel('time [s]')
ylabel('-diff log|CWT(ridge)|/(2\pi) [Hz]')
hold off
