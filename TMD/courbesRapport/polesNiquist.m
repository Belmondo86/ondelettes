clear all;
close all;

mu = 0.5;
omega0 = 2*pi;
zeta0 = 0.0;
omega1 = 2*pi/(1+mu);
nZeta1 = 100000;
Zeta10 = 0;
Zeta11 = 0.95;
Zeta1 = linspace(Zeta10, Zeta11, nZeta1);
zeta1Points = linspace(Zeta10, Zeta11, 4);


realOnly = false;

pointMarkers = {'o','s','^','v','d','>','<','p','h','+','*','.','x'};


%%
racines = nan(4, length(Zeta1));
for k = 1:length(Zeta1)
    zeta1 = Zeta1(k);
    racines(:,k) = polesSystemeLineaire(mu, omega0, omega1, zeta0, zeta1);
end
racines = racines(~isnan(racines));
if realOnly
    racines = racines(imag(racines) >= 0); %on garde seulement les poles � partie imaginaire positive pour l'affichage
end


%%
f = figure('Name', ['mu=', num2str(mu), ' ; f0=', num2str(omega0/2/pi) ,' ; (1+mu)w1/w0= ',...
    num2str((1+mu)*omega1/omega0), ' ; z0=', num2str(zeta0), ' ; z1={', num2str(zeta1Points)]);



zeta1 = Zeta1(1);

%poles
ax = axes('Parent', f);
hold(ax, 'on');
colors = get(ax, 'ColorOrder');
index = get(ax,'ColorOrderIndex');
poles = plot(real(racines)', imag(racines)', '.', 'Parent', ax, 'Color', colors(index, :));
xlabel('Re(p_k)');
ylabel('Im(p_k)');

points = zeros(1,length(zeta1Points));
for i=1:length(zeta1Points)
    zeta1 = zeta1Points(i);
    mark = pointMarkers{mod(i-1,length(pointMarkers))+1};
    racines = polesSystemeLineaire(mu, omega0, omega1, zeta0, zeta1);
    if realOnly
        racines = racines(imag(racines) >= 0);
    end
    points(i) = plot(real(racines), imag(racines), mark, 'Parent', ax, 'MarkerSize', 10, 'LineWidth', 2,...
        'DisplayName', ['\zeta_1 = ', num2str(zeta1)]);
end

hold(ax, 'off');

legend(points, 'Location', 'best');

