function el_finis_nonlin()

results_name = 'test';

if exist('D:\simulations elements finis non lin\data', 'dir')
    saveFolder = 'D:\simulations elements finis non lin\data';
    saveFolder = 'D:\simulations elements finis non lin\data\tests';
elseif exist('C:\Users\raphael\Documents\resultats simul diff finies', 'dir')
    saveFolder = 'C:\Users\raphael\Documents\resultats simul diff finies';
else
    error(' ');
end

solve_ODE = 0;
plot_results = 0; % sauvegarde dans tous les cas
disp_freq_nonlin = 0;

nonLin = 1;
local_nonlin = 1; % non linearite sur ddl px_nonlin, ou sur tous les ddl
inertia_vehicles = 1;
presence_PL = 1;
temp_variation = 1; % variations E par temp�rature
shock_mode = 0;

t_tot = 1*3600;
Fe = 2000; % freq echantillonnage calcul EDP
Fe2 = 50; % freq reechantillonnage
T0_resampl = 100; % decoupage en tps, economie memoire

%% donn�es pont

% https://patrimoine.auvergnerhonealpes.fr/dossier/pont-ferroviaire-dit-viaduc-de-la-voulte/f4343ca4-6470-465c-b523-977429ed0d0d

L = 50; % longueur du pont
E0 = 30e9; % module d'young du b�ton
E = E0;
rho = 2500; % masse volumique du b�ton
l_pont = 6; % largeur du pont
h_pont = 2.4; % hauteur pont
e_pont = 0.3; % epaisseur beton
J = (l_pont*h_pont^3 - (l_pont-2*e_pont)*(h_pont-2*e_pont)^3) / 12; % moment quadratique du pont
mu = (l_pont*h_pont - (l_pont-2*e_pont)*(h_pont-2*e_pont)) * rho; % masse lin�ique du pont
amort_deg = 4; % degr� derivation spatial amortissement, (deg 0: Viscous Air Damping, deg 2 : ?, deg 4 : Kelvin-Voigt damping)
amort = 1.8e8; % coefficient d'amortissement, 7.6e3, -7.2e5, 1.83e8


%% integration spatiale

N = 31; % nb de points ds l'espace
dx = L / (N-1);

%% non linearite

g = 9.81;

% courbure statique
C_static0 = g*mu/(E*J) * ( -(dx*(1:N-2)-L/2).^2/2 + L^2/8).'; % corrig� plus bas pour le cas non-lin

% parametres
x_nonlin = 2/5*L; % endroit du defaut, pour d�faut local
x_nonlin = 0.45*L; % endroit du defaut, pour d�faut local
px_nonlin = round(x_nonlin/dx);
x_nonlin = px_nonlin*dx;
if local_nonlin
    sigma0 = C_static0(px_nonlin)*E*h_pont/2; % contrainte au d�faut local
else
    sigma0 = max(C_static0)*E*h_pont/2; % contrainte mi-trav�e
end
sigma0 = sigma0 + 0.4e6;
threshold_nonlin = sigma0 * 2/(E*h_pont); % courbure nonlin�arit�
slope_nonlin_E = 0.97; % E2 = slope_nonlin*E
slope_nonlin_moment1 = 2*slope_nonlin_E/(1+slope_nonlin_E); % nonlin�arit� sur le moment en fonction de celle sur le module E
slope_nonlin_moment_local = 0.8;

% precontrainte etc.
fleche_pont = g*mu*L^4/(384*E*J); % fleche (https://appx.cchic.ca/svilleneuve/materiaux/chap10.pdf)
sigma_min = sigma0 - E*max(C_static0)*h_pont/2; % contrainte de compression minimale (intrados mi_trav�e)
sigma_max = sigma0 + E*max(C_static0)*h_pont/2; % contrainte de compression maximale (extrados mi_trav�e)
delta_sigma_1t = - E * g*1e3*L/4 / (E*J) * h_pont/2; % compression perdue vehicule 1 tonne mi-trav�e (https://en.wikipedia.org/wiki/Euler%E2%80%93Bernoulli_beam_theory)
delta_sigma_1t_12m = - E * g*1e3*(L-12)/4 / (E*J) * h_pont/2; % compression perdue vehicule 12m, 1 tonne mi-trav�e

    function M = nonlin1(C)
        M = ((slope_nonlin_moment1-1)*E*J)*(C - threshold_nonlin).*(C > threshold_nonlin); % pas de nonlin pour C negatif car pont d�j� courb� statiquement
    end

    function M = nonlin2(C) % ne pas utiliser pour poutre creuse !
        signC = sign(C);
        C = abs(C);
        
        l0 = sigma0/E ./ C;
        E2 = slope_nonlin_E*E;
        
        coeffA = C*(E2-E)/2;
        coeffB = - C*E2*h_pont - (1-E2/E)*sigma0;
        coeffC = C.*l0.^2*(E-E2)/2 + C*E2*h_pont^2/2 + (h_pont-l0)*(1-E2/E)*sigma0;
        
        x0 = (-coeffB - sqrt(coeffB.^2 - 4*coeffA.*coeffC)) ./ (2*coeffA);
        
        M = (l_pont*(C*E.*(l0.^3+x0.^3)/3 + C*E2.*((h_pont-x0).^3-l0.^3)/3 + ((h_pont-x0).^2-l0.^2)/2*(1-E2/E)*sigma0) - C*E*J)...
            .*(C.*signC > threshold_nonlin).*signC;
        M(isnan(M)) = 0; % C=0 => M=0
    end

func_nonlin_global0 = @nonlin1;

% figure;
% c0 = linspace(-3*threshold_nonlin, 3*threshold_nonlin, 1000).';
% plot(c0, func_nonlin_global0(c0));
% % plot(c0, E*J*c0 + func_nonlin_global0(c0));

select_nonlin_local = zeros(N-2, 1);
select_nonlin_local(px_nonlin) = 1;

    function M = nonlin_local1(C)
        M = select_nonlin_local .* (((slope_nonlin_moment_local-1)*E*J)*(C - threshold_nonlin).*(C > threshold_nonlin)); % pas de nonlin pour C negatif car pont d�j� courb� statiquement
    end

func_nonlin_local0 = @nonlin_local1;

% figure;
% c0 = linspace(-3*threshold_nonlin, 3*threshold_nonlin, 1000);
% plot(c0, select_nonlin_local.' * func_nonlin_local0(select_nonlin_local * c0));
% plot(c0, E*J*c0 + select_nonlin_local.' * func_nonlin_local0(select_nonlin_local * c0));


%% donn�es temps

ti = 0;
tf = t_tot;
dt = 1/Fe;

T = ti:dt:tf;


%% donn�es v�hicules

 % https://www.jcss-lc.org/ (2.5 traffic)

% lois voitures
tau_vehicle = [6 6]; % constante de tps loi sans memoire, deux sens de circulation
m0_vehicle = 1.25e3; % esp�rance masse v�hicules https://carlabelling.ademe.fr/chiffrescles/r/evolutionMasseMoyenne#:~:text=En%202019%2C%20la%20masse%20moyenne,moyenne%20totale%20atteignant%201240%20kg.&text=par%20les%20ventes-,En%202019%2C%20la%20masse%20moyenne*%20a%20augment%C3%A9%20de%2010%20kg,moyenne%20totale%20atteignant%201240%20kg.
sigma_m_vehicle = 0.25e3; % �cart type masse v�hicules
c0_vehicle = 55/3.6; % esp�rance vitesse v�hicules
sigma_c_vehicle = 10/3.6; % �cart type vitesse v�hicules
d_axles_vehicle = 2.6; % distance essieux v�hicules https://www.courroie-distribution.fr/blog/empattement-role-et-calcul/#:~:text=L'empattement%20est%20donc%20primordial,empattement%20de%202%2C60%20m%C3%A8tres.

% conversion loi log-normale
sigma2_m_log = log((sigma_m_vehicle/m0_vehicle)^2 + 1);
mu_m_log = log(m0_vehicle) - sigma2_m_log/2;

% tirages al�atoire trafic
t_vehicles_left = [0, 0]; % premi�re voiture � t = 0
while t_vehicles_left(end) <= t_tot
    t_vehicles_left(end+1) = t_vehicles_left(end) + exprnd(tau_vehicle(1));
end
t_vehicles_left = t_vehicles_left(2:end-1);
m_vehicles_left = exp(mu_m_log + sqrt(sigma2_m_log)*randn(size(t_vehicles_left)));
c_vehicles_left = c0_vehicle + sigma_c_vehicle*randn(size(t_vehicles_left));

t_vehicles_right = 0;
while t_vehicles_right(end) <= t_tot
    t_vehicles_right(end+1) = t_vehicles_right(end) + exprnd(tau_vehicle(end));
end
t_vehicles_right = t_vehicles_right(2:end-1);
m_vehicles_right = m0_vehicle + sigma_m_vehicle*randn(size(t_vehicles_right));
c_vehicles_right = c0_vehicle + sigma_c_vehicle*randn(size(t_vehicles_right));

if any(c_vehicles_left <= 0) || any(c_vehicles_right <= 0)
    error('c_vehicles <= 0');
end

% r�partition sur essieux
t_vehicles_left = [t_vehicles_left, t_vehicles_left + d_axles_vehicle./c_vehicles_left];
m_vehicles_left = 1/2 * [m_vehicles_left, m_vehicles_left];
c_vehicles_left = [c_vehicles_left, c_vehicles_left];
t_vehicles_right = [t_vehicles_right, t_vehicles_right + d_axles_vehicle./c_vehicles_right];
m_vehicles_right = 1/2 * [m_vehicles_right, m_vehicles_right];
c_vehicles_right = [c_vehicles_right, c_vehicles_right];

% PL
t_PL_left = [];
m_PL_left = [];
c_PL_left = [];
t_PL_right = [];
m_PL_right = [];
c_PL_right = [];

if presence_PL
    jourPL = floor(rand()*176) + 1;
    [Tdj1, Tdj2] = getData(jourPL);
    Tdj1.time = 2*Tdj1.time; % division par deux densit� camions
    Tdj2.time = 2*Tdj2.time;
    %%%%% TEST %%%%%
    Tdj1.time = 10*Tdj1.time;
    Tdj2.time = 10*Tdj2.time;
    %%%%%%%%%%%%%%%%
    Tdj1 = Tdj1(Tdj1.time <= t_tot, :);
    Tdj2 = Tdj2(Tdj2.time <= t_tot, :);
    
    for kpl = 1:size(Tdj1, 1)
        ke = 1;
        d_essieu = 0;
        while ke <= 8 && ~isnan(Tdj1.(sprintf('d_%d', ke))(kpl))
            t_PL_left(end+1) = Tdj1.time(kpl);
            m_PL_left(end+1) = Tdj1.(sprintf('pmoy_%d', ke))(kpl) * 100; % conversion quintaux -> kg
            c_PL_left(end+1) = Tdj1.vit(kpl) * (50/90) / 3.6; % r�duction autoroute/route, puis conversion km/h -> m/s
            d_essieu = d_essieu + Tdj1.(sprintf('d_%d', ke))(kpl) / 100; % conversion cm -> m
            t_PL_left(end) = t_PL_left(end) + d_essieu/c_PL_left(end);
            ke = ke + 1;
        end
    end
    for kpl = 1:size(Tdj2, 1)
        ke = 1;
        d_essieu = 0;
        while ke <= 8 && ~isnan(Tdj2.(sprintf('d_%d', ke))(kpl))
            t_PL_right(end+1) = Tdj2.time(kpl);
            m_PL_right(end+1) = Tdj2.(sprintf('pmoy_%d', ke))(kpl) * 100; % conversion quintaux -> kg
            c_PL_right(end+1) = Tdj2.vit(kpl) * (50/90) / 3.6; % r�duction autoroute/route, puis conversion km/h -> m/s
            d_essieu = d_essieu + Tdj2.(sprintf('d_%d', ke))(kpl) / 100; % conversion cm -> m
            t_PL_right(end) = t_PL_right(end) + d_essieu/c_PL_right(end);
            ke = ke + 1;
        end
    end
end

% concat�nation v�hicules et PL
t_vehicles = [t_vehicles_left, t_vehicles_right, t_PL_left, t_PL_right];
m_vehicles = [m_vehicles_left, m_vehicles_right, m_PL_left, m_PL_right];
c_vehicles = [c_vehicles_left, -c_vehicles_right, c_PL_left, -c_PL_right];

% % v�rification entr� dans le tps imparti
% m_vehicles = m_vehicles(t_vehicles < t_tot);
% c_vehicles = c_vehicles(t_vehicles < t_tot);
% t_vehicles = t_vehicles(t_vehicles < t_tot);

if shock_mode
    t_vehicles = []; % pas de vehicule
    m_vehicles = [];
    c_vehicles = [];
    t_vehicles_left = [];
    m_vehicles_left = [];
    c_vehicles_left = [];
    t_vehicles_right = [];
    m_vehicles_right = [];
    c_vehicles_right = [];
    t_PL_left = [];
    m_PL_left = [];
    c_PL_left = [];
    t_PL_right = [];
    m_PL_right = [];
    c_PL_right = [];
end

% decoupage en temps (tps calcul)
T0_veh = 100; % intervalles tps vehicules
T_vehicles = cell(1, floor(t_tot/T0_veh)+1);
M_vehicles = cell(1, floor(t_tot/T0_veh)+1);
C_vehicles = cell(1, floor(t_tot/T0_veh)+1);
for kt = 1:length(T_vehicles)
    Ikt = find(t_vehicles <= kt*T0_veh & t_vehicles + L./abs(c_vehicles) >= (kt-1)*T0_veh);
    T_vehicles{kt} = t_vehicles(Ikt);
    M_vehicles{kt} = m_vehicles(Ikt);
    C_vehicles{kt} = c_vehicles(Ikt);
end

%% temperature

thetaE = -4.5e-3; % /�C, dependance E en T (Xia et al., Long term vibration monitoring of an RC slab: Temperature and humidity effect)
thetaAmort = 1e-2;
deltaT = 10; % �C, variation temperature sur la journ�e
periodeTemp = 24*3600; % periode variation temperature
var_temp = @(t) (deltaT/2) * sin(2*pi*t/periodeTemp);
coeff_E_temp = @(t) 1 + thetaE * var_temp(t);
coeff_amort_temp = @(t) 1 + thetaAmort * var_temp(t);

%% matrices

% masse
Mr = mu * eye(N-2);

% derivee seconde
% avec 0 en x = 0 et en x = L (CL, � partir d'ordre 0 et 2)
D2 = zeros(N-2); % equa diff
D2(1, 1:2) = [-2 1];
for i = 2:(N-3)
    D2(i, i-1:i+1) = [1 -2 1];
end
D2(end, end-1:end) = [1 -2];
D2 = 1/dx^2 * D2;

% rigidit�
Kr0 = E*J * D2^2;
Kr = Kr0;

% amortissement
if amort_deg == 0
    Cr = amort * eye(N-2);
elseif amort_deg == 2
    Cr = amort * D2;
elseif amort_deg == 4
    Cr = amort * D2^2;
end
Cr0 = Cr;

% op�rateur acc�l�ration coriolis
A1r = zeros(N-2);
A1r(1, 1:2) = [0 1/2];
for i = 2:N-3
    A1r(i, i-1:i+1) = [-1/2 0 1/2];
end
A1r(end, end-1:end) = [-1/2 0];
A1r = 2/dx * A1r; % � multiplier par la vitesse

% op�rateur acc�l�ration centrip�te
A2r = D2; % � multiplier par la vitesse au carr�


% precalcul pour cas lineaire dans inertie vehicules
Mr_Kr0 = Mr\Kr;
Mr_Kr = Mr_Kr0;
Mr_Cr0 = Mr\Cr;
Mr_Cr = Mr_Cr0;
invMr = inv(Mr);

% % derivation nonlin
% d2_nonlin = zeros(1, N-2);
% d2_nonlin(px_nonlin-3:px_nonlin-1) = 1/dx^2 * [1 -2 1];
% courbure_vect0 = zeros(N-2, 1);
% courbure_vect0(px_nonlin-2) = 1;

% precalcul
F0 = zeros(N, 1);
F = zeros(N-2, 1);
influenceM = zeros(1, N);
influenceMc = zeros(1, N);
influenceMc2 = zeros(1, N);
% D2_nonlin_courbure_vect0 = D2 * courbure_vect0;

%% courbure statique, avec non-lin�art�

    function c_static = get_C_static(C_static_init, n_iter)
        y_static = D2 \ C_static_init;
%         figure;
%         plot(y_static);
%         hold on
%         plt1 = plot(y_static); drawnow;
            for k = 1:n_iter % methode de newton, � peu pr�s
                force_err = Kr*y_static + Mr*g*ones(N-2, 1);
                if nonLin && local_nonlin
                    force_err = force_err + D2*func_nonlin_local0(D2*y_static);
                elseif nonLin && ~local_nonlin
                    force_err = force_err + D2*func_nonlin_global0(D2*y_static);
                end
                y_static = y_static - Kr\force_err;
                %             input(num2str(max(abs(force_err))));
                %             set(plt1, 'YData', y_static); drawnow;
            end
            c_static = D2*y_static;
    end
C_static = get_C_static(C_static0, 100);
M_static_nonlin_global = func_nonlin_global0(C_static);
M_static_nonlin_local = func_nonlin_local0(C_static);
func_nonlin_global = @(C) func_nonlin_global0(C+C_static) - M_static_nonlin_global;
func_nonlin_local = @(C) func_nonlin_local0(C+C_static) - M_static_nonlin_local;

%% disp freq propre, freq excitation, precontrainte

% affichage
disp('%%%%%%%%%%%%%%%%%%%%%%%%%');
clockTime = clock;
fprintf('%d:%02d\n', clockTime(4:5));

dispStresses0 = 1;
dispFreqs0 = 1;
plotShapes0 = 0;
plotDefModales(dispStresses0, dispFreqs0, plotShapes0, L, E, J, mu, N, Mr, Cr, Kr, fleche_pont, sigma0, sigma_min, sigma_max, delta_sigma_1t, delta_sigma_1t_12m);

%% disp freq nonlin

if disp_freq_nonlin
    pos00 = 1;
    pos0 = logspace(log10(pos00)-6, log10(pos00), 10000);
    pos0 = [-flip(pos0), 0, pos0];
    phi1 = sin(pi*(1:N-2)/(N-1))';
    Mmod1 = phi1' * Mr * phi1;
    Kxmod1 = phi1' * Kr * phi1*pos0;
    if nonLin && local_nonlin
        Kxmod1 = Kxmod1 + phi1' * D2*func_nonlin_local(D2*phi1*pos0);
    elseif nonLin && ~local_nonlin
        Kxmod1 = Kxmod1 + phi1' * D2*func_nonlin_global(D2*phi1*pos0);
    end
    Kmod1 = diff(Kxmod1)./diff(pos0);
    Kmod1 = [Kmod1(1), 1/2*(Kmod1(1:end-1)+Kmod1(2:end)), Kmod1(end)];
    
    % plot freq "locale", ie petite amplitude autour de la position
    local_freq = 1/(2*pi)*sqrt(Kmod1/Mmod1);
    figure;
    plot(pos0, local_freq);
    xlabel('Position [m]');
    ylabel('Frequency [Hz]');
    
    % plot freq "globale", ie grande amplitude autour de 0
    Gmod1 = [0, cumsum(1/2*(Kxmod1(1:end-1)+Kxmod1(2:end)).*diff(pos0))];
    ampl0 = [];
    global_freq = [];
    Nmin = 10; % nb min integration
    for kpos01 = 1:length(pos0)-Nmin
        if pos0(kpos01+Nmin) >= 0 || abs(pos0(kpos01)) < 10*min((abs(pos0(pos0 ~= 0))))
            break
        end
        kpos02 = round(length(pos0)/2) + 1;
        while kpos02 < length(pos0)
            if Gmod1(kpos02+1) > Gmod1(kpos01)
                break
            else
                kpos02 = kpos02+1;
            end
        end
        if kpos02 == length(pos0) || kpos01+Nmin >= kpos02-Nmin
            continue
        end
        
        ampl0(end+1) = (pos0(kpos02) - pos0(kpos01))/2;
        Imod1 = sqrt(1./(Gmod1(kpos01) - Gmod1(kpos01+Nmin:kpos02-Nmin)));
        tau012 = sqrt(2*Mmod1) * sum(1/2*(Imod1(1:end-1)+Imod1(2:end)).*diff(pos0(kpos01+Nmin:kpos02-Nmin)));
        % integrale limite gauche
        dGpos01 = (Gmod1(kpos01+1)-Gmod1(kpos01)) / (pos0(kpos01+1)-pos0(kpos01));
        dx01 = pos0(kpos01+Nmin) - pos0(kpos01);
        tau012 = tau012 + sqrt(2*Mmod1)*2*sqrt(dx01/(-dGpos01));
        % integrale limite droite
        dGpos02 = (Gmod1(kpos02)-Gmod1(kpos02-1)) / (pos0(kpos02)-pos0(kpos02-1));
        dx02 = (Gmod1(kpos01) - Gmod1(kpos02-Nmin))/dGpos02;
        tau012 = tau012 + sqrt(2*Mmod1)*2*sqrt(dx02/(dGpos02));
        global_freq(end+1) = 1/tau012;
    end
    
    figure;
    plot(ampl0, global_freq);
    xlabel('Amplitude [m]');
    ylabel('Frequency [Hz]');
end

%% integration numerique
if ~solve_ODE
    return
end

Y0 = zeros(N-2, 1);
V0 = zeros(N-2, 1);
if shock_mode
%     V0 = 1e-2*rand(N-2, 1).*(1:N-2).'/N; % choc tous modes
%     V0 = zeros(N-2, 1);
%     V0(1) = 1;
    V0 = 1000*1e-2*sin(pi*(1:N-2).'/(N-1)); % choc mode 1
end
YV0 = [Y0; V0];

% temps de calcul
computationTime = now;

% wait bar
[initWaitBar, updateWaitBar, closeWaitBar] = getWaitBar(t_tot, 'windowTitle', 'Computing ODE',...
    'msg', '', 'minimumBeepTime', 0);
initWaitBar();

n_waitbar = -1;
    function flag = updateWaitBar2(t, ~, ~)
        flag = 0;
        n_waitbar = n_waitbar + 1;
        if mod(n_waitbar, 200) ~= 0
            return
        end
        if ~isempty(t)
            updateWaitBar(t(1), sprintf('t = %.1fs', t(1)))
        end
    end

% integration
options = odeset('OutputFcn', @updateWaitBar2);

% if ~resample_data
%     [~, YV] = ode45(@D, T, YV0, options);
%     YV = YV.';
% else
% rapport reechantillonnage

pFe2 = Fe2/gcd(Fe, Fe2);
qFe = Fe/gcd(Fe, Fe2);
if any([pFe2, qFe] > 100)
    [pFe2, qFe] = rat(Fe2/Fe, 1e-2);
    Fe2 = Fe*pFe2/qFe;
end

if T0_resampl*Fe ~= round(T0_resampl*Fe) || T0_resampl*Fe2 ~= round(T0_resampl*Fe2)
    error('sampling problem');
end

% CI et preparation
T = 1/Fe2 *(0:floor(t_tot*Fe2));
N_samples = ceil(t_tot/T0_resampl);
YV = nan(length(YV0), length(T));
VA = nan(length(YV0), length(T));
YV0k = YV0;

% temperature
Temp = var_temp(T);

% bool nonlinearite atteinte
nonlin_reached = false(length(YV0)/2, length(T));
if nonLin && local_nonlin
    nonlin_reached = false(1, length(T));
elseif nonLin && ~local_nonlin
    nonlin_reached = false(length(YV0)/2, length(T));
else
    nonlin_reached = [];
end

for Kt = 0:N_samples-1
    % influence temp�rature
    if temp_variation
        E = coeff_E_temp(Kt*T0_resampl) * E0;
        Kr = coeff_E_temp(Kt*T0_resampl) * Kr0;
        Mr_Kr = coeff_E_temp(Kt*T0_resampl) * Mr_Kr0;
        Cr = coeff_amort_temp(Kt*T0_resampl) * Cr0;
        Mr_Cr = coeff_amort_temp(Kt*T0_resampl) * Mr_Cr0;
%         C_static = get_C_static(C_static0, 100); % pas d'update si modification de E dynamique seulement
%         M_static = func_nonlin_global0(C_static); % idem
%         func_nonlin_global = @(C) func_nonlin_global0(C+C_static) - M_static;
    end
    
    if Kt >= 2
        YVkm2 = YVkm1; % YV_{k-2} = YV_{k-1}
        VAkm2 = VAkm1;
    end
    if Kt >= 1
        YVkm1 = YVk; % YV_{k-1} = YV_{k}
        VAkm1 = VAk;
    end
    
    if Kt >= 1
        YV0k = YVkm1(:, end); % vecteur initial
    end
    if Kt < N_samples-1
        Tk = Kt*T0_resampl + 1/Fe*(0:T0_resampl*Fe); % vecteur tps sur la periode
    else
        Tk = Kt*T0_resampl + 1/Fe*(0:floor((t_tot-Kt*T0_resampl)*Fe));
    end
    
    [~, YVk] = ode45(@D, Tk, YV0k, options);
    YVk = YVk.';
    VAk = nan(size(YVk));
    for kta = 1:size(YVk, 2)
        VAk(:, kta) = D(Tk(kta), YVk(:, kta));
    end
    
    % reechant en Kt-1
    if Kt == 0
        YVkm0k_resampled = resample(YVk.', pFe2, qFe).';
        VAkm0k_resampled = resample(VAk.', pFe2, qFe).';
        modified_indexes = 1:size(YVkm0k_resampled, 2);
        YV(:, modified_indexes) = YVkm0k_resampled(:, 1:end);
        VA(:, modified_indexes) = VAkm0k_resampled(:, 1:end);
    elseif Kt == 1
        YVkm1k = [YVkm1(:, 1:end-1), YVk];
        VAkm1k = [VAkm1(:, 1:end-1), VAk];
        YVkm1k_resampled = resample(YVkm1k.', pFe2, qFe).';
        VAkm1k_resampled = resample(VAkm1k.', pFe2, qFe).';
        modified_indexes = (Kt-1)*T0_resampl*Fe2+1 : (Kt-1)*T0_resampl*Fe2 + size(YVkm1k_resampled, 2);
        YV(:, modified_indexes) = YVkm1k_resampled(:, 1:end);
        VA(:, modified_indexes) = VAkm1k_resampled(:, 1:end);
    elseif Kt >= 2
        YVkm2km1k = [YVkm2(:, 1:end-1), YVkm1(:, 1:end-1), YVk];
        VAkm2km1k = [VAkm2(:, 1:end-1), VAkm1(:, 1:end-1), VAk];
        YVkm2km1k_resampled = resample(YVkm2km1k.', pFe2, qFe).';
        VAkm2km1k_resampled = resample(VAkm2km1k.', pFe2, qFe).';
        modified_indexes = (Kt-1)*T0_resampl*Fe2+1 : (Kt-2)*T0_resampl*Fe2 + size(VAkm2km1k_resampled, 2);
        YV(:, modified_indexes) = YVkm2km1k_resampled(:, T0_resampl*Fe2+1 : end);
        VA(:, modified_indexes) = VAkm2km1k_resampled(:, T0_resampl*Fe2+1 : end);
    end
    
    % nonlin atteinte
    if nonLin && local_nonlin
        nonlin_reached(modified_indexes) = logical(select_nonlin_local.' * (func_nonlin_local(D2 * YV(1:end/2, modified_indexes)) ~= -M_static_nonlin_local));
    elseif nonLin && ~local_nonlin
        nonlin_reached(:, modified_indexes) = func_nonlin_global(D2 * YV(1:end/2, modified_indexes)) ~= -M_static_nonlin_global;
    end
end

if any(isnan(YV), 'all')
    error('concatenation error');
end

closeWaitBar();

% temps de calcul
computationTime = now - computationTime;
computationTime = days(computationTime);
formatsTime = {'MM:SS', 'HH:MM:SS'};
computationTime = datestr(computationTime, formatsTime{logical(hms(computationTime))+1});
disp(computationTime);

% mise en forme des matrices
Y = YV(1:N-2, :);
V = YV(N-1:end, :);
A = VA(N-1:end, :);


%% enregistrement

listing = dir(saveFolder);
listingNames = {listing.name};
nbSimul = 0;
for kname = 1:length(listingNames)
    name1 = strsplit(listingNames{kname}, '_');
    name1 = name1{1};
    if length(name1) > 5 && strcmp(name1(1:5), 'simul')
        nbSimul = max(nbSimul, str2double(name1(6:end)));
    end
end
if ~isempty(results_name)
    simul_name = [sprintf('simul%d_', nbSimul+1), results_name, sprintf('_N%d_T%d', [N, t_tot])];
else
    simul_name = sprintf('simul%d_N%d_T%d', [nbSimul+1, N, t_tot]);
end
if inertia_vehicles
    simul_name = [simul_name, '_inertievehicules'];
end
if ~presence_PL
    simul_name = [simul_name, '_sansPL'];
end
if temp_variation
    simul_name = [simul_name, '_variationstemperature'];
end
if shock_mode
    simul_name = [simul_name, '_modechoc'];
end
if nonLin && local_nonlin
    simul_name = [simul_name, '_nonlin_local'];
elseif nonLin && ~local_nonlin
    simul_name = [simul_name, '_nonlin_global'];
else % lin
    simul_name = [simul_name, '_lin'];
end

clear YV VA
clear YVk YVkm1 YVkm2 YVkm2km1k YVkm1k YVkm2km1k_resampled YVkm1k_resampled Tk
clear VAk VAkm1 VAkm2 VAkm2km1k VAkm1k VAkm2km1k_resampled VAkm1k_resampled
clear initWaitBar updateWaitBar closeWaitBar
clear T_vehicles C_vehicles M_vehicles
clear listing listingNames nbSimul
clear options formatsTime
clear Tdj1 Tdj2

% sauvegarde
save(fullfile(saveFolder, simul_name), '-v7.3', '-nocompression');



%% affichage

if plot_results
    el_finis_nonlin_display();
end


%% fonction integration numerique


    function dYddY = D(t, YdY)
        % vehicules sur le pont
        I = find(T_vehicles{floor(t/T0_veh)+1} < t...
            & T_vehicles{floor(t/T0_veh)+1} + L./abs(C_vehicles{floor(t/T0_veh)+1}) > t);
        t_on_bridge = T_vehicles{floor(t/T0_veh)+1}(I);
        m_on_bridge = M_vehicles{floor(t/T0_veh)+1}(I);
        c_on_bridge = C_vehicles{floor(t/T0_veh)+1}(I);
        pos_ind = (c_on_bridge .* (t - t_on_bridge) + (c_on_bridge < 0)*L)/dx + 1;
        
        % influence poids
        F0 = zeros(N, 1);
        for k_v = 1:length(pos_ind)
            % s�paration sur les deux points les plus proches
            p0 = floor(pos_ind(k_v));
            F0(p0) = F0(p0) + (p0+1 - pos_ind(k_v)) * m_on_bridge(k_v); % bras de levier
            F0(p0+1) = F0(p0+1) + (pos_ind(k_v) - p0) * m_on_bridge(k_v);
        end
        
        F = - g/dx*F0(2:N-1);
        
        if inertia_vehicles
            % influence  inertie
            pos_ind = round(pos_ind); % pas de s�paration sur les deux points pour l'inertie
            influenceM = zeros(1, N);
            influenceMc = zeros(1, N);
            influenceMc2 = zeros(1, N);
            for k_v = 1:length(pos_ind)
                influenceM(pos_ind(k_v)) = influenceM(pos_ind(k_v)) + m_on_bridge(k_v);
                influenceMc(pos_ind(k_v)) = influenceMc(pos_ind(k_v)) + m_on_bridge(k_v) * c_on_bridge(k_v);
                influenceMc2(pos_ind(k_v)) = influenceMc2(pos_ind(k_v)) + m_on_bridge(k_v) * c_on_bridge(k_v)^2;
            end
            
            % matrice de masse ajoutee
            M_ajout = 1/dx * diag(influenceM(2:N-1)); % supression des ddl des CL
            M_ajout_c = 1/dx * diag(influenceMc(2:N-1));
            M_ajout_c2 = 1/dx * diag(influenceMc2(2:N-1));
        end
        
        if ~inertia_vehicles && ~nonLin
            % acceleration
            dYddY = [YdY(N-1:end);...
                -Mr_Kr * YdY(1:N-2) - Mr_Cr * YdY(N-1:end) + invMr * F];
        elseif inertia_vehicles && ~nonLin
            dYddY = [YdY(N-1:end);...
                (Mr + M_ajout) \ (- (Kr + M_ajout_c2*A2r) * YdY(1:N-2) - (Cr + M_ajout_c*A1r) * YdY(N-1:end) + F)];
        else % nonLin
            if local_nonlin
%                 courbure = d2_nonlin * YdY(1:N-2);
% %                 F_nonlin = (1-slope_nonlin_moment1)*E*J* ((courbure > threshold_nonlin) * (courbure-threshold_nonlin)...
% %                     + (courbure < -threshold_nonlin) * (courbure+threshold_nonlin)) * D2_nonlin_courbure_vect0;
%                 F_nonlin = (slope_nonlin_moment1-1)*E*J* (courbure > threshold_nonlin)*(courbure-threshold_nonlin)*D2_nonlin_courbure_vect0; % non lin�arit� due � la flexion vers le haut inutile
                F_nonlin = D2*func_nonlin_local(D2*YdY(1:N-2));
            else
                F_nonlin = D2*func_nonlin_global(D2*YdY(1:N-2));
            end
            
            if ~inertia_vehicles
                dYddY = [YdY(N-1:end);...
                -Mr_Kr * YdY(1:N-2) - Mr_Cr * YdY(N-1:end) + invMr * (F - F_nonlin)];
            else
                dYddY = [YdY(N-1:end);...
                (Mr + M_ajout) \ (- (Kr + M_ajout_c2*A2r) * YdY(1:N-2) - (Cr + M_ajout_c*A1r) * YdY(N-1:end) + F - F_nonlin)];
            end
        end
        
        
    end


%%

% K =
% E*J*
% [1  0  0  0  0  0  0... ; -> CL \nu(x=0) = 0
%  1 -3  3 -1  0  0  0... ; -> CL \partial^3\nu/\partail x^3(x=0) = 0
%  1 -4  6 -4  1  0  0... ; -> eq diff
%  0  1 -4  6 -4  1  0... ; -> eq diff
% ...
%     ... 1 -4  6 -4  1  0  0 ; -> eq diff
%     ... 0  1 -4  6 -4  1  0 ; -> eq diff
%     ... 0  0  1 -4  6 -4  1 ; -> eq diff
%     ... 0  0  0  1 -3  3 -1 ;  -> CL \partial^3\nu/\partail x^3(x=L) = 0
%     ... 0  0  0  0  0  0  1 ;]  -> CL \nu(x=L) = 0
%
%
%
% M = mu*dx*
% [0  0  0  0  0  0  0... ; -> CL \nu(x=0) = 0
%  0  0  0  0  0  0  0... ; -> CL \partial^3\nu/\partail x^3(x=0) = 0
%  0  0  1  0  0  0  0... ; -> eq diff
%  0  0  0  1  0  0  0... ; -> eq diff
% ...
%     ... 0  0  1  0  0  0  0 ; -> eq diff
%     ... 0  0  0  1  0  0  0 ; -> eq diff
%     ... 0  0  0  0  1  0  0 ; -> eq diff
%     ... 0  0  0  0  0  0  0 ;  -> CL \partial^3\nu/\partail x^3(x=L) = 0
%     ... 0  0  0  0  0  0  0 ;]  -> CL \nu(x=L) = 0
%
%
%
% Ensuite, il faut laisser � 0 tous les termes en position 1, 2, N-2 et N-1 dans la matrice C, et dans l'excitation.
% Le plus simple je pense, c'est d'utiliser une matrice, Mddl, qui va enlever ces ddl.
%
% Mddl = diag([0, 0, ones(1, N-2), 0, 0]);
% M = mu*Mddl*eye(N)
% q = Mddl*q; (q est un vecteur colone)
% mu_q = Mddl*mu_q;  (mu_q est une matrice)
%
%
% dis moi si �a marche
%
% h�site pas si t'as des questions, bon courage
%

end