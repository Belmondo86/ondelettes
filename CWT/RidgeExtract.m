function ridge = RidgeExtract(X,Y,Q,fmin,fmax,NbFreq,varargin)
%%
p = inputParser;
%% parametres par defaut
etDef = 1;
efDef = 1;
MaxSlopeRidgeDef = 1;
ctLeftDef = 3;
ctRightDef = 3;
% ctLeftDef = 0;
% ctRightDef = 0;
NbMaxRidgesDef = 100;
NbMaxParallelRidgesDef = 1;
MinModuDef = 0;
StopWhenIncreasingDef = false;
LengthMinRidgeDef = 0;
ReleaseTimeDef = X(1);
WaveletDef = nan;
SmoothDampingDef = true;
MotherWaveletDef = 'cauchy';
DerivationOrderDef = 0;
FrequencyScaleDef = 'lin';
XLimRidgeDef = [];
ctRidgeDef = [];
SquaredCWTDef = false;

%%
addRequired(p,'X')
addRequired(p,'Y')
addRequired(p,'Q')
addRequired(p,'fmin')
addRequired(p,'fmax')
addRequired(p,'NbFreq')
addParameter(p,'et',etDef);
addParameter(p,'ef',efDef);
addParameter(p,'MaxSlopeRidge',MaxSlopeRidgeDef);
addParameter(p,'ctLeft',ctLeftDef);
addParameter(p,'ctRight',ctRightDef);
addParameter(p,'NbMaxRidges',NbMaxRidgesDef);
addParameter(p,'NbMaxParallelRidges',NbMaxParallelRidgesDef);
addParameter(p,'MinModu', MinModuDef);
addParameter(p,'StopWhenIncreasing', StopWhenIncreasingDef);
addParameter(p,'LengthMinRidge',LengthMinRidgeDef);
addParameter(p,'ReleaseTime',ReleaseTimeDef);
addParameter(p,'Wavelet', WaveletDef);
addParameter(p,'SmoothDamping', SmoothDampingDef); % spline smoothing de l'amplitude pour lisser zeta(t)
addParameter(p,'MotherWavelet', MotherWaveletDef);
addParameter(p,'DerivationOrder', DerivationOrderDef);
addParameter(p,'FrequencyScale', FrequencyScaleDef);
addParameter(p,'XLimRidge', XLimRidgeDef);
addParameter(p,'ctRidge', ctRidgeDef);
addParameter(p,'SquaredCWT', SquaredCWTDef);


parse(p,X,Y,Q,fmin,fmax,NbFreq,varargin{:});

%
et = p.Results.et ;
ef = p.Results.ef ;
slopeRidge = p.Results.MaxSlopeRidge ;
ctLeft =  p.Results.ctLeft;
ctRight =  p.Results.ctRight;
NbMaxRidges = p.Results.NbMaxRidges;
NbMaxParallelRidges = p.Results.NbMaxParallelRidges;
MinModu = p.Results.MinModu;
StopWhenIncreasing = p.Results.StopWhenIncreasing;
LengthMinRidge = p.Results.LengthMinRidge;
ReleaseTime = p.Results.ReleaseTime;
wavelet = p.Results.Wavelet;
SmoothDamping = p.Results.SmoothDamping;
MotherWavelet = p.Results.MotherWavelet;
DerivationOrder = p.Results.DerivationOrder;
FrequencyScale = p.Results.FrequencyScale;
XLimRidge = p.Results.XLimRidge;
ctRidge = p.Results.ctRidge;
SquaredCWT = p.Results.SquaredCWT;

if isempty(XLimRidge)
    XLimRidge = [X(1), X(end)];
end
if isempty(ctRidge)
    ctRidge = [0, 0];
elseif length(ctRidge) == 1
    ctRidge = [ctRidge, ctRidge];
end


%%
if iscolumn(X)
    X=transpose(X);
end
%%  %%  %%  %%  %%  %%

switch FrequencyScale
    case 'lin'
        WvltFreq = linspace(fmin, fmax, NbFreq); % Freq de calcul de la CWT
    case 'log'
        WvltFreq = logspace(log10(fmin), log10(fmax), NbFreq); % Freq de calcul de la CWT
end

if isnan(wavelet)
    wavelet = WvltComp(X, Y, WvltFreq, Q, 'MotherWavelet', MotherWavelet, 'DerivationOrder', DerivationOrder); % Calcul CWT
end

% if SquaredCWT
%     wavelet = sqrt(wavelet);
% end

% % calcul du bruit
% noise = exp(mean(mean(log(abs(wavelet)))));
% %noise = mean(mean(abs(wavelet)));
% MinModu = MinModu * noise;

mesu = raindrop(wavelet); % Recherche des maximum locaux en echelle

if SquaredCWT
    MinModu = MinModu^2;
end
mesu(mesu<MinModu) = NaN; % retrait des max. locaux < MinModu

% retrait des max locaux paralleles excessifs
for iT = 1:length(X)
    localMax = mesu(:, iT);
    localMax = localMax(~isnan(localMax));
    if length(localMax) > NbMaxParallelRidges
        localMax = sort(localMax, 'descend');
        localMin = localMax(NbMaxParallelRidges);
        mesu(mesu(:, iT) < localMin, iT) = nan;
    end
end

%effets de bords
[~, DeltaT] = FTpsi_DeltaT(Q, MotherWavelet);

DeltaTimeLeft = ctLeft * DeltaT(WvltFreq); % ct * a * Delta T_psi gauche = largeur effet de bord gauche
DeltaTimeRight = ctRight * DeltaT(WvltFreq); % ct * a * Delta T_psi droite = largeur effet de bord droite
RangeLeft = (X - transpose(DeltaTimeLeft)) >= X(1); % Zone d'effets de bord gauche
RangeRight = (X + transpose(DeltaTimeRight)) <= X(end); % Zone d'effets de bord droite
mesuEdge = mesu;
mesuEdge(~(RangeLeft & RangeRight)) = NaN; % Max locaux hors zone effets de bord seulement
%% si Y_in = 0 au debut ou fin : zero-padding non voulu. On le retire
% if ~isnan(Y)
%     IndBegin = find(Y~=0,1); % eventuel zero-padding ou apparente (succession de 0 au d�but du signal)
%     IndEnd = find(Y~=0,1,'last');% Idem fin de signal
% else
%     IndBegin = 1;
%     IndEnd = length(X);
% end

%%
Fs=1/mean(X(2:end)-X(1:end-1)); %Freq echantillonnage
LengthMin = max(3,round(LengthMinRidge*Fs)); % Nb points mini d'un ridge
if iscolumn(X)
    X=transpose(X); % X_in en ligne
end
%%
[ny,nx] = size(mesu); % ny = nb de freq de CWT, nx = nb de points du signal

ind_mesu = ~isnan(mesu);
Ind_Mesu = cell(1, nx);
for kx = 1:nx
    Ind_Mesu{kx} = find(ind_mesu(:, kx));
end

%%
ridge.time = {};
ridge.val = {};
ridge.freq = {};
ridge.pha = {};
for C_r=1:NbMaxRidges % Pour chaque ridge
    [M2,I] = max(mesuEdge(:)); % Maximum global hors effets de bord pour initialiser le chainage
    
    if M2<MinModu || isnan(M2)
        break
    end
    
    ind_freq = NaN(size(X)) ; % Indice des fr�quences du ridge
    ridge.time{C_r} = NaN(size(X)) ; % Instants associ�s
    ridge.val{C_r}  = NaN(size(X)) ; % Valeur (complexe) de la CWT
    
    [a,b] = ind2sub(size(mesu),I);    % Conversion de l'index du max global en freq,instant
    
    ind_freq(1) = a ;
    ridge.time{C_r}(1) = b ;
    ridge.val{C_r}(1)  = wavelet(a,b);
    
    C_ind = 2;
    while (ridge.time{C_r}(C_ind-1)+et<=nx) % On chaine vers l'avant
        
        % pente max dans le plan tps-freq
        if ind_freq(C_ind-1) == 1
            WvltFreqIncrement = WvltFreq(ind_freq(C_ind-1)+1) - WvltFreq(ind_freq(C_ind-1));
        elseif ind_freq(C_ind-1) == length(WvltFreq)
            WvltFreqIncrement = WvltFreq(ind_freq(C_ind-1)) - WvltFreq(ind_freq(C_ind-1)-1);
        else
            WvltFreqIncrement = (WvltFreq(ind_freq(C_ind-1)+1) - WvltFreq(ind_freq(C_ind-1)-1))/2;
        end
        ef = ceil( et*slopeRidge * WvltFreq(ind_freq(C_ind-1))^2 / (Fs * WvltFreqIncrement));
        ef = min(ef, ny); % inutile de chercher en dehors des bornes de frequence
        
        I_t = ridge.time{C_r}(C_ind-1) + 1; % indice d'instant suivant
        
        I_f = Ind_Mesu{I_t}; % Correction des indices de freq.
        I_f = I_f(I_f >= ind_freq(C_ind-1) - ef);
        I_f = I_f(I_f <= ind_freq(C_ind-1) + ef);
        [~, Ind_I_f] = min(abs(I_f - ind_freq(C_ind-1)));
        I_f = I_f(Ind_I_f);
        
        if isempty(I_f) || mesu(I_f, I_t) <= MinModu ||...
                ( StopWhenIncreasing && mesu(I_f, I_t) > abs(ridge.val{C_r}(C_ind-1)) ) ||...
                isnan(mesu(I_f, I_t)) || I_f==1 || I_f==ny % Condition de fin : module trop petit ou extremite de la fen�tre frequentielle choisie
            break
        else
            ind_freq(C_ind) = I_f ; % Assignation freq.
            ridge.time{C_r}(C_ind) = I_t ; % Assignation instant
            ridge.val{C_r}(C_ind)  = wavelet(I_f, I_t); % Assignation valeur
            
            C_ind = C_ind + 1; % Increment
        end
    end
    NoNaN = ~isnan(ridge.time{C_r}); % On liste les instants ou on a identifier le ridge jusqu'ici
    ind_freq(NoNaN) = flip(ind_freq(NoNaN) ); % On en inverse le sens (pour chainer vers l'arriere)
    ridge.time{C_r}(NoNaN) = flip(ridge.time{C_r}(NoNaN)); % idem instants
    ridge.val{C_r}(NoNaN) = flip(ridge.val{C_r}(NoNaN)); % idem valeurs
    
    while ridge.time{C_r}(C_ind-1)-et>=1 %On chaine vers l'arri�re
        
        % pente max dans le plan tps-freq
        if ind_freq(C_ind-1) == 1
            WvltFreqIncrement = WvltFreq(ind_freq(C_ind-1)+1) - WvltFreq(ind_freq(C_ind-1));
        elseif ind_freq(C_ind-1) == length(WvltFreq)
            WvltFreqIncrement = WvltFreq(ind_freq(C_ind-1)) - WvltFreq(ind_freq(C_ind-1)-1);
        else
            WvltFreqIncrement = (WvltFreq(ind_freq(C_ind-1)+1) - WvltFreq(ind_freq(C_ind-1)-1))/2;
        end
        ef = ceil( et*slopeRidge * WvltFreq(ind_freq(C_ind-1))^2 / (Fs * WvltFreqIncrement));
        ef = min(ef, ny); % inutile de chercher en dehors des bornes de frequence
        
        I_t = ridge.time{C_r}(C_ind-1) - 1; % indice d'instant suivant
        
        I_f = Ind_Mesu{I_t}; % Correction des indices de freq.
        I_f = I_f(I_f >= ind_freq(C_ind-1) - ef);
        I_f = I_f(I_f <= ind_freq(C_ind-1) + ef);
        [~, Ind_I_f] = min(abs(I_f - ind_freq(C_ind-1)));
        I_f = I_f(Ind_I_f);
        
        if isempty(I_f) || mesu(I_f, I_t) <= MinModu ||...
                ( StopWhenIncreasing && mesu(I_f, I_t) < abs(ridge.val{C_r}(C_ind-1)) ) ||...
                isnan(mesu(I_f, I_t)) || I_f==1 || I_f==ny % Condition de fin : module trop petit ou extremite de la fen�tre frequentielle choisie
            break
        else
            ind_freq(C_ind) = I_f ; % Assignation freq.
            ridge.time{C_r}(C_ind) = I_t ; % Assignation instant
            ridge.val{C_r}(C_ind)  = wavelet(I_f, I_t); % Assignation valeur
            
            C_ind = C_ind+1; %Increment (comme on a inverser le sens, on incremente bien en +1 pour aller vers l'arriere
        end
    end
    
    NoNaN = 1:C_ind-1; % On liste les instants retenus
    ridge.time{C_r}=ridge.time{C_r}(NoNaN); % On retire les instants sans ridge
    ridge.val{C_r}=ridge.val{C_r}(NoNaN); % idem valeur
    ind_freq = ind_freq(NoNaN); % idem freq
    
    [ridge.time{C_r},Isort] = sort(ridge.time{C_r}); % On remet les instants dans l'ordre croissant
    ind_freq = ind_freq (Isort); % Idem freq (ordre chronologique)
    ridge.val{C_r} = ridge.val{C_r}(Isort); % Idem valeur (ordre chronologique)
    
    mesu(sub2ind([ny,nx],ind_freq,ridge.time{C_r})) = NaN; % On retire le ridge de nos maximum locaux potentiellement associ�s a un ridge pour ne pas retomber toujours sur le meme
    mesuEdge(sub2ind([ny,nx],ind_freq,ridge.time{C_r})) = NaN; % Idem hors effets de bord
    
    % On convertit les indices en frequences
    WvltFreqLocal = [WvltFreq(ind_freq-1); WvltFreq(ind_freq); WvltFreq(ind_freq+1)];
    
    mesuEdgeLocal = NaN(3, length(ind_freq));
    for iT = 1:length(ind_freq)
        mesuEdgeLocal(:,iT) = [...
            wavelet(ind_freq(iT)-1, ridge.time{C_r}(iT));...
            wavelet(ind_freq(iT), ridge.time{C_r}(iT));...
            wavelet(ind_freq(iT)+1, ridge.time{C_r}(iT))];
    end
    
    % calcul du ridge sur le sommet de l'interpolation quadratiques des 3
    % points du sommet
    [ridge.freq{C_r}, ridge.val{C_r}] = localMax3Points(WvltFreqLocal, mesuEdgeLocal);
    
    if SquaredCWT
        ridge.val{C_r} = sqrt(ridge.val{C_r});
    end
    
    % On convertit les indices en temps
    ridge.time{C_r} = X(ridge.time{C_r});
end
%% retrait des ridges trop courts
d_r=0;
% for C_r=1:length(ridge.time)
%     if length(ridge.time{C_r-d_r})<=LengthMin
%         FieldList = fieldnames(ridge);
%         for C_Field = 1:length(FieldList)
%             FieldName = FieldList{C_Field};
%             ridge.(FieldName)=ridge.(FieldName)([1:C_r-d_r-1, C_r-d_r+1:length(ridge.(FieldName))]);
%         end
%
%         d_r=d_r+1;
%     end
% end

%% arret si pas de ridge et retrait des ridges vides

if isempty(ridge.time)
    return
end

C_r = 1;
while C_r <= length(ridge.time)
    indNotNan = ~isnan(ridge.freq{C_r}); % on supprime les zones vides
    ridge.time{C_r} = ridge.time{C_r}(indNotNan);
    ridge.freq{C_r} = ridge.freq{C_r}(indNotNan);
    ridge.val{C_r} = ridge.val{C_r}(indNotNan);
    
    if length(ridge.time{C_r}) <= 1
        ridge.time(C_r) = [];
        ridge.freq(C_r) = [];
        ridge.val(C_r) = [];
    else
        C_r = C_r+1;
    end
end

%% Calcul de la phase (argument complexe) et de la fr�quence d�riv�e de la phase
for C_r = 1:length(ridge.time)
    ridge.pha{C_r} = angle(ridge.val{C_r});
end

for C_r = 1:length(ridge.time)
    ridge.pha2{C_r} = ridge.pha{C_r};
    
    if SquaredCWT
        phaseDiscontinuity = pi;
    else
        phaseDiscontinuity = 2*pi;
    end
    
    % continuit� de la phase
    phaseDiscontinuityIncrements = zeros(size(ridge.pha2{C_r}));
    for kt = 1:(length(ridge.pha2{C_r})-1)
        if abs(ridge.pha2{C_r}(kt+1)+phaseDiscontinuity-ridge.pha2{C_r}(kt)) < abs(ridge.pha2{C_r}(kt+1)-ridge.pha2{C_r}(kt))
            phaseDiscontinuityIncrements(kt+1) = 1;
        elseif abs(ridge.pha2{C_r}(kt+1)-phaseDiscontinuity-ridge.pha2{C_r}(kt)) < abs(ridge.pha2{C_r}(kt+1)-ridge.pha2{C_r}(kt))
            phaseDiscontinuityIncrements(kt+1) = -1;
        end
    end
    ridge.pha2{C_r} = ridge.pha2{C_r} + cumsum(phaseDiscontinuityIncrements) * phaseDiscontinuity;
end

for C_r = 1:length(ridge.time)
    deltaT = (ridge.time{C_r}(end)-ridge.time{C_r}(1)) / length(ridge.time{C_r});
    freq2 = diff(ridge.pha2{C_r})./ deltaT;
    ridge.freq2{C_r} = [freq2(1), (freq2(1:end-1)+freq2(2:end))/2, freq2(end)] / (2*pi);
end

%% frequence instantanee alternative plus lisse, en reliant les discontinuites (saut d'une freq. a une autre)
for C_r = 1:length(ridge.time)
    FreqLeft = ridge.freq{C_r}(1:end-1);
    FreqRight = ridge.freq{C_r}(2:end);
    Range = diff(ridge.freq{C_r})~=0; % Liste des sauts de freq.
    Range(end)=1;
    ListFreq = [FreqLeft(1),(  FreqLeft(Range) + FreqRight(Range)  )/2]; % a chaque saut, on associe la moyenne de la freq avant et apr�s
    ListTime = ridge.time{C_r}(logical([1,Range])); % instants associes aux sauts de freq.
    ridge.freq3{C_r} = interp1(ListTime,ListFreq,ridge.time{C_r}); % interpolation avec ces valeurs pour tous les autres instants
    
    ridge.freq3{C_r}(1)=ridge.freq{C_r}(1); % correction premier point
    if isnan(ridge.freq3{C_r}(end))
        ridge.freq3{C_r}(end)=ridge.freq{C_r}(end); % correction dernier point
    end
end
%% evaluation de la dissipation
for C_r = 1:length(ridge.time)
    % amortissement
    logAmpl = log(abs(ridge.val{C_r}));
    %     if SmoothDamping
    %         freqmoy = mean(ridge.freq{C_r});
    %         deltaT = Q / (2*pi*freqmoy);
    %         logAmpl = gaussianSmooth(logAmpl, round(deltaT*Fs/1));
    %     end
    ridge.damping{C_r} = -diff(logAmpl)*Fs; % -A'/A = lambda
    ridge.damping{C_r} = ([ridge.damping{C_r}(1), ridge.damping{C_r}] + ...
        [ridge.damping{C_r}, ridge.damping{C_r}(end)]) /2;
    if SmoothDamping % gaussian filter
        freqmoy = mean(ridge.freq{C_r});
        deltaT = Q / (2*pi*freqmoy);
        deltaT = deltaT/5;
%         deltaN = round(deltaT*Fs/4);
%         Nhalf = round(length(ridge.damping{C_r})/2);
        Nhalf = ceil(5*deltaT*Fs);
        Nhalf = min(Nhalf, length(ridge.damping{C_r}));
        filterCoeffs = nan(1, 2*Nhalf+1);
        for kfilter = 1:length(filterCoeffs)
            filterCoeffs(kfilter) = exp( -((kfilter-1-Nhalf)/Fs)^2 / (2*deltaT^2));
        end
        filterCoeffs = filterCoeffs / sum(filterCoeffs);
        dampingData = ridge.damping{C_r};
        dampingData = [dampingData(1)*ones(1, Nhalf), dampingData, dampingData(end)*ones(1, Nhalf)];
        dampingData = filter(filterCoeffs, 1, dampingData);
        ridge.damping{C_r} = dampingData(2*Nhalf+1:end);
    end
    ridge.damping2{C_r} = ridge.damping{C_r} ./ (2*pi*ridge.freq{C_r}); % lambda/omega_d
    ridge.damping3{C_r} = ridge.damping2{C_r} ./ sqrt(1 + ridge.damping2{C_r}.^2); % lambda/omega_n
    
    % Si mesure de vitesse
    ridge.bandwidth{C_r} = -diff(log(abs(ridge.val{C_r})))*Fs; % -A'/A
    ridge.bandwidth{C_r} = ([ridge.bandwidth{C_r}(1), ridge.bandwidth{C_r}] + ...
        [ridge.bandwidth{C_r}, ridge.bandwidth{C_r}(end)]) /2;
    ridge.bandwidth{C_r} = ridge.bandwidth{C_r}/(2*pi); % = -A'/2*pi*A
    
    ridge.inv2Q{C_r} = ridge.bandwidth{C_r}./(ridge.freq3{C_r}); % = -A'/2*pi*f*A
    
    % Si mesure d'acceleration et frequence variable
    ridge.bandwidth2{C_r} = -diff(log(abs(ridge.val{C_r}./ridge.freq3{C_r})))*Fs; % -A'/A + f'/f
    ridge.bandwidth2{C_r} = [ridge.bandwidth2{C_r}(1),ridge.bandwidth2{C_r}]/(2*pi); % -A'/2*pi*A + f'/2*pi*f
    ridge.inv2Q2{C_r} = ridge.bandwidth2{C_r}./(ridge.freq3{C_r}); % -A'/2*pi*A*f + f'/2*pi*f^2
    
    % Si mesure de deplacement et frequence variable
    ridge.bandwidth3{C_r} = -diff(log(abs(ridge.val{C_r}.*ridge.freq3{C_r})))*Fs; % -A'/A - f'/f
    ridge.bandwidth3{C_r} = [ridge.bandwidth3{C_r}(1),ridge.bandwidth3{C_r}]/(2*pi); % -A'/2*pi*A - f'/2*pi*f
    ridge.inv2Q3{C_r} = ridge.bandwidth3{C_r}./(ridge.freq3{C_r}); % -A'/2*pi*A*f + f'/2*pi*f^2
    
end

%% NaN pour effets de bord, etc.
FieldList = fieldnames(ridge);
for C_Field = 1:length(FieldList)
    FieldName = FieldList{C_Field};
    if ~strcmp(FieldName,'time')
        ridge.([FieldName,'raw']) = ridge.(FieldName); % on nomme "ridge.trucraw" la grandeur "truc" hors et dans effets de bord
    end
end
FieldList = fieldnames(ridge);
for C_r = 1:length(ridge.time)
    DeltaTimeLeft = ctLeft * DeltaT(ridge.freq{C_r}); % ct * Delta t_psi/a associes a gauche
    DeltaTimeRight = ctRight * DeltaT(ridge.freq{C_r}); % ct * Delta t_psi/a associes a droite
    
    
    RangeEdgeLeft = (ridge.time{C_r}-DeltaTimeLeft) >= X(1); % Liste des instants ou t + ct*Delta t_psi/a reste dans les limites du signal (gauche)
    RangeEdgeRight = (ridge.time{C_r}+DeltaTimeRight) <= X(end); % Liste des instants ou t + ct*Delta t_psi/a reste dans les limites du signal (droite)
    RangeEdge = RangeEdgeLeft & RangeEdgeRight; % intersection des deux listes = liste des instants hors effets de bord pour le ridge considere
    
    RangeRelease = (ridge.time{C_r}-DeltaTimeLeft) >= ReleaseTime; % Liste des instants verifiant la meme condition a partir de l'instant de relachement (debut de la reponse libre)
    
    DeltaTimeRidgeLeft = ctRidge(1)* DeltaT(ridge.freq{C_r}); % ct * Delta t_psi/a associes a gauche
    DeltaTimeRidgeRight = ctRidge(2) * DeltaT(ridge.freq{C_r}); % ct * Delta t_psi/a associes a droite
    RangeRidgeEdgeLeft = (ridge.time{C_r} - DeltaTimeRidgeLeft) >= XLimRidge(1); % Liste des instants ou t + ct*Delta t_psi/a reste dans les limites du signal (gauche)
    RangeRidgeEdgeRight = (ridge.time{C_r} + DeltaTimeRidgeRight) <= XLimRidge(2); % Liste des instants ou t + ct*Delta t_psi/a reste dans les limites du signal (droite)
    RangeRidgeEdge = RangeRidgeEdgeLeft & RangeRidgeEdgeRight; % intersection des deux listes = liste des instants hors effets de bord pour le ridge considere
    
    RangeFinal = RangeEdge & RangeRelease & RangeRidgeEdge; % intersection des listes
    
    %%
    for C_Field = 1:length(FieldList)
        FieldName = FieldList{C_Field};
        if ~strcmp(FieldName,'time') && ~strcmp(FieldName(end-2:end),'raw')
            ridge.(FieldName){C_r}(~RangeFinal) = NaN;  % NaN pour les pts proches des  bord et/ou proches du relachement
        end
    end
    
end
%% Retrait des ridges entierement dans la zone d'effets de bord
C_r=1;
while  C_r <= length(ridge.time)
    if all(isnan(ridge.val{C_r-d_r}))
        FieldList = fieldnames(ridge);
        
        for C_Field = 1:length(FieldList)
            FieldName = FieldList{C_Field};
            ridge.(FieldName) = ridge.(FieldName)([1:C_r-1, C_r +1:length(ridge.(FieldName))]);
        end
    else
        indNotNan = ~isnan(ridge.freq{C_r}); % on supprime les zones vides
        
        for C_Field = 1:length(FieldList)
            FieldName = FieldList{C_Field};
            ridge.(FieldName){C_r} = ridge.(FieldName){C_r}(indNotNan);
        end
        C_r = C_r + 1;
    end
end