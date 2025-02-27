pendule = TMDpendule(9.81^2, 1, 9.81, @(theta,omega) 1*sign(omega)*abs(omega)^(0));
pendule.reponseLibre(pi-0.05, 0, 400);

%%
mr = TMDmasseressort(1, 0, @(x, v) 0.01*sign(v)*abs(v)^(1) + sign(x));
mr.reponseLibre(0, 2, 500);

%%
pendule = TMDpendule(9.81^2, 1, 9.81, @(theta,omega) 50*omega*(abs(theta)<0.1));
tour = Structure(50, 50, @(x,v) 0.0*v, {{pendule, 1}});
tour.reponseLibreAvecTMD(0, 1, 200);

%%
l = 1;
pendule = TMDpendule(l^2, 1, l, @(theta,omega) 0);
tour = Structure(50, 50, @(x,v) 10*v, {{pendule, 1}});
tour.reponseForceeAvecTMD(0, 0, 100, @(t) [1 0], true);

%%
k = 1/1.01^2;
c = 2*sqrt(k)*sqrt(3*0.01/(8*(1+0.01)));
% c = 0.05;
% c = 10;
mr = TMDmasseressort(1, k, @(x, v) c*v);
% mr.reponseLibre(0, 1, 200);
tour = Structure(100, 100, @(x,v) 10*v, {{mr, 1}});
tour = Structure(100, 100, @(x,v) 0*v, {{mr, 1}});
[t, X] = tour.reponseLibre(1, 0, 500, true);
x = X(:, 1);
CWT(t, x, 1/(2*pi)*exp(linspace(-0.1, 0.1, 200)), 2, 'fourier', 1);
% tour.diagrammeBode(1, 1, 1/(2*pi)*exp(linspace(-0.3, 0.3, 100)), 500, true);

%%
mr = TMDmasseressort(1, 2, @(x, v) 0.01*sign(v));
[t, x] = mr.reponseLibre(0, 1, 200);
CWT(t, x, 1/(2*pi)*exp(linspace(-1, 1, 100)), 500);

%%
t = linspace(0, 100, 5000);
x = sin(2*pi*t) + 2*sin(4*pi*t+1);
CWT(t, x, logspace(-0.5, 0.5, 100), 200);

%%
mu = 0.05;
m0 = 1/mu;
m1 = 1;
k0 = 1/mu;
k1 = (1/(1+mu))^2;
c0 = 0;
c1 = 2/(1+mu)*sqrt(3*mu/8/(1+mu));
c1 = 2/(1+mu)*sqrt(mu/(1+mu));
c1 = 2/(1+mu)*sqrt(3*mu/8/(1+mu))*60227/43301;
mr = TMDmasseressort(m1, k1, @(x, v) c1*v);
tour = Structure(m0, k0, @(x,v) 0*v, {{mr, 1}});
[t, X] = tour.reponseLibre(0, 1, 100, true);
% x = X(:, 1);
% CWT(t, x, 1/(2*pi)*exp(linspace(-0.1, 0.1, 200)), 2, 'fourier', 1);
tour.diagrammeBode(1, 1, 1/(2*pi)*logspace(-0.3, 0.3, 100), 200, true);


%%
mr = TMDmasseressort(1, 1, @(x, v) 0.2*sign(v)*abs(v)^(1));
tour = Structure(50, 50, @(x,v) 0.0*v, {{mr, 1}});
tour.reponseLibre(1, 0, 200, true);

mr = TMDmasseressort(1, 0, @(x, v) 2*sign(v)*abs(v)^(1));
tour = Structure(50, 50, @(x,v) 0.0*v, {{mr, 1}});
tour.reponseLibre(1, 0, 200, true);

%%
% pendule = TMDpendule(9.81^2, 1, 9.81, @(theta,omega) 1*sign(omega)*abs(omega)^(0));
% [t, x] = pendule.reponseLibre(pi-0.01, 0, 350);
pendule = TMDpendule(9.81^2, 1, 9.81, @(theta,omega) 1*omega);
[t, x] = pendule.reponseLibre(pi-0.01, 0, 1000);

Q = 2;
fmin = 0.01;
fmax = 0.2;
NbFreq = 600;

T = linspace(t(1), t(end), 1000*20/(2*pi)*2);
X = interp1(t, x, T);

WaveletMenu(fmin,fmax,NbFreq, T, X);

%%
mr = TMDmasseressort(1, 1, @(x,v) 0.001*sign(v));
[t, x] = mr.reponseLibre(0, 1, 1000);

Q = 2;
fmin = 0.01;
fmax = 0.2;
NbFreq = 100;

T = linspace(t(1), t(end), 1000*30/(2*pi)*2);
X = interp1(t, x, T);


WaveletMenu(T, X, 'fmin', fmin, 'fmax', fmax, 'NbFreq', NbFreq);

%%
t = linspace(-10, 10, 100000);
N = -0.4;
figure;
hold on
for n=N
    plot(t, real((1i./(t+1i)).^(n+1)));
    plot(t, imag((1i./(t+1i)).^(n+1)));
end
hold off

%%
fmin = 0.5;
fmax = 1.5;
NbFreq = 50;

T = linspace(0, 100, 100*40+1);
T = T(1:(end-1));
X = (sin(2*pi*T)+0).*(T<50);

figure;
ax = plot(T, X);

WaveletMenu(fmin,fmax,NbFreq, 'WaveletPlot', ax);

%%
fmin = 0.5;
fmax = 1.5;
NbFreq = 50;

T = linspace(0, 100, 100*40+1);
T = T(1:(end-1));
X = (sin(2*pi*T)+0).*exp(-T/10);

figure;
ax = plot(T, X);

WaveletMenu(fmin,fmax,NbFreq, 'WaveletPlot', ax);


%%
mu = 0.01;
m0 = 1/mu;
m1 = 1;
k0 = 1/mu;
k1 = (1/(1+mu))^2;
c0 = 0;
c1 = 2/(1+mu)*sqrt(3*mu/8/(1+mu));
% c1 = 2/(1+mu)*sqrt(mu/(1+mu));
mr = TMDmasseressort(m1, k1, @(x, v) 0.08*sign(v)*abs(v)^0.1);
tour = Structure(m0, k0, @(x,v) 0*v, {{mr, 1}});
[t, X] = tour.reponseLibre(0, 1, 500, true);
x = X(:,1)';

T = linspace(t(1), t(end), 500/2/pi*200);
X = interp1(t, x, T);

fmin = 0.5/2/pi;
fmax = 1.5/2/pi;
NbFreq = 200;

figure;
plt = plot(T, X);

WaveletMenu('WaveletPlot', plt, 'fmin', 0.05, 'fmax', 0.3);

%%
M = @(mu, alpha, X) max (real (polesSystFrac(mu, 1, X(1), 0, X(2), alpha)));
F = @(mu, alpha) M(mu, alpha, fminsearch(@(X) M(mu, alpha, X), [1 1]));

mu = 2;

n = 41;
alphas = linspace(0, 2, n);
lambdas = zeros(1, n);
for ka = 1:n
    lambdas(ka) = F(mu, alphas(ka));
end

f = figure;
ax = axes(f);
plot(ax, alphas, lambdas);


%%
p = 21;
q = 20;
mu = 5;
alpha = 2;

theta = linspace(0, 2*q*pi, 1000000);

x = sin(theta);
y = sin(theta) + mu*sin(p/q*theta);
X = sign(x) .* abs(x).^alpha;
Y = sign(y) .* abs(y).^alpha;
Cx = X .* sin(theta);
Cy = Y .* sin(theta);

f = figure;
ax = axes(f);
hold on
plot(theta, X, 'Parent', ax);
plot(theta, Y, 'Parent', ax);
hold off


Ix = mean(Cx(1:end-1))
Iy = mean(Cy(1:end-1))


%% test integrale Ialpha

alpha = 0.;

theta = linspace(0, 2*pi, 10000);

f = @(lambda, theta) (1 + lambda^2 + 2*lambda*cos(theta)).^((alpha-1)/2) .* (1 + lambda*exp(1i*theta));
I = @(lambda) sum(f(lambda, theta(1:end-1))) * (theta(2)-theta(1));

f2 = @(lambda, theta) theta.^0 * (1+lambda.^2).^((alpha-1)/2) * (1 + (alpha-1)/2*lambda^2/(1+lambda^2)) ;
I2 = @(lambda) sum(f2(lambda, theta(1:end-1))) * (theta(2)-theta(1));

Lambda = logspace(-3, 1, 1000);

LI = nan(1, length(Lambda));
LI2 = nan(1, length(Lambda));
for k = 1:length(Lambda)
    LI(k) = I(Lambda(k));
    LI2(k) = I2(Lambda(k));
end


fig = figure;
ax = axes(fig);
hold on
plot(Lambda, LI, 'Parent', ax);
plot(Lambda, LI2, '--', 'Parent', ax);
hold off

max(abs(LI-LI2)./LI)

%% courbes ondelette cauchy

n= 20;

t = linspace(-1, 1, 10000);
w = linspace(0, 40, 10000);
psi = (1i./(t+1i)).^(n+1);
psiF = 2*pi*w.^n.*exp(-w)/gamma(n+1).*(w>=0);

fig = figure;
ax = axes(fig);
hold on
plot(t, real(psi), 'Parent', ax);
plot(t, imag(psi), 'Parent', ax);
xlabel(ax, 't');
ylabel(ax, '\psi');
legend('\Re \psi', '\Im \psi');
hold off

fig = figure;
ax = axes(fig);
plot(w, psiF, 'Parent', ax);
xlabel(ax, '\omega');
ylabel(ax, '\psi');

%% courbes ondelette morlet

delta = 3;

t = linspace(-20, 20, 10000);
w = linspace(0, 2, 10000);

psi = exp(-t.^2/(2*delta^2)).*exp(1i*t);
psiF = delta*sqrt(2*pi)*exp(-(w-1).^2*delta^2/2);

fig = figure;
ax = axes(fig);
hold on
plot(t, real(psi), 'Parent', ax);
plot(t, imag(psi), 'Parent', ax);
xlabel(ax, '$t$');
ylabel(ax, '$\psi$');
legend('\Re \psi', '\Im \psi');
hold off

fig = figure;
ax = axes(fig);
hold on
plot(w, psiF, 'Parent', ax);
plot(w, zeros(size(w)), 'Parent', ax);
xlabel(ax, '$\omega$');
ylabel(ax, '$\hat\psi$');
legend('\Re \psi', '\Im \psi');
hold off

%% courbes ondelette

t = linspace(0, 100, 10000);
x = cos(2*pi*t + cos(2*pi*t/20)) + cos(4*pi*t + t.^2/200);

fig = figure;
ax = axes(fig);
h = plot(t, x, 'Parent', ax);


WaveletMenu('WaveletPlot', h, 'fmin', 0.5, 'fmax', 3,...
    'NbFreq', 100, 'Q', 10, 'MaxParallelRidges', 2);




%%

w1 = 2*pi;
w2 = 2*pi+0.1;

t = linspace(0, 500, 50000);

x1 = exp(-0.2*t).*sin(w1*t);
x2 = exp(-0.2*t).*sin(w2*t);

f = figure;
ax = axes(f);
hold(ax, 'on');
h = plot(t, x1+x2, 'parent', ax);


WaveletMenu('WaveletPlot', h, 'fmin', 0.9, 'fmax', 1.1,...
    'NbFreq', 300, 'Q', 100, 'MaxParallelRidges', 2);




%%

w = 2*pi;

t = linspace(-100, 100, 10000);

x = (1-0.2*t).*sin(w1*t);

f = figure;
ax = axes(f);
hold(ax, 'on');
h = plot(t, x, 'parent', ax);


WaveletMenu('WaveletPlot', h, 'fmin', 0.9, 'fmax', 1.1,...
    'NbFreq', 300, 'Q', 50, 'MaxParallelRidges', 2);




%% test integrale Ialpha 2

alpha = 2;

theta = linspace(0, 2*pi, 10000);

f = @(lambda, theta) (1 + lambda^2 + 2*lambda*cos(theta)).^((alpha-1)/2) .* (1 + lambda*exp(1i*theta));
I = @(lambda) sum(f(lambda, theta(1:end-1))) * (theta(2)-theta(1));

Lambda = logspace(-3, 1, 1000);

LI = nan(1, length(Lambda));
LI2 = nan(1, length(Lambda));
for k = 1:length(Lambda)
    LI(k) = I(Lambda(k));
    LI2(k) = I(1/Lambda(k));
end


fig = figure;
ax = axes(fig);
hold on
plot(Lambda, LI, 'Parent', ax);
plot(Lambda, LI2, 'Parent', ax);
plot(Lambda, LI+LI2, '--', 'Parent', ax);
hold off

max(abs(LI-LI2)./LI)



%% test integrale Ialpha 3

alpha = 0.9;

theta = linspace(0, 2*pi, 10000);

f = @(lambda, theta) (1 + lambda^2 + 2*lambda*cos(theta)).^((alpha-1)/2) .* (1 + lambda*exp(1i*theta));
I = @(lambda) sum(f(lambda, theta(1:end-1))) * (theta(2)-theta(1));

Lambda = logspace(-3, 1, 1000);

LI = nan(1, length(Lambda));
LI2 = nan(1, length(Lambda));
for k = 1:length(Lambda)
    LI(k) = I(Lambda(k));
    LI2(k) = I(1/Lambda(k));
end


fig = figure;
ax = axes(fig);
hold on
plot(Lambda, LI, 'Parent', ax);
plot(Lambda, LI2, 'Parent', ax);
plot(Lambda, LI+LI2, '--', 'Parent', ax);
plot(Lambda, LI./Lambda + LI2.*Lambda, ':', 'Parent', ax);
hold off


%% gaussienne

alpha = 16;
lambda = 0.1;

phi = @(w) alpha*sqrt(2*pi)*exp(-(w-1).^2*alpha^2/2);
dphi = @(w) -alpha^2*(w-1) .* phi(w);


omega = linspace(0.5, 1.5, 1000);
Tomega0 = 1/2*phi(omega);
Tomega1 = abs(1/2*phi(omega) + lambda*1i/2*dphi(omega)./omega);

fig = figure;
ax = axes(fig);
plot(omega, Tomega0, 'Parent', ax);
xlabel(ax, '$\omega$');
ylabel(ax, '$\left|T[u]\right|$');

fig = figure;
ax = axes(fig);
plot(omega, Tomega1, 'Parent', ax);
xlabel(ax, '$\omega$');
ylabel(ax, '$\left|T[u]\right|$');


%% sÚparation ridges

Q = 15;
alpha = sqrt(2)*Q;

phi = @(w) alpha*sqrt(2*pi)*exp(-(w-1).^2*alpha^2/2);

omega = linspace(0.8, 1.2, 200);
t = linspace(0, 100, 2);
[T,Omega] = meshgrid(t, omega) ;

Tomega1 = 1/2*phi(0.95*omega) + 1/2*phi(1.05*omega);
Tomega2 = transpose(Tomega1) * t.^0;


fig = figure;
ax = axes(fig);
plot(omega, Tomega1, 'Parent', ax);
xlabel(ax, '$\omega$');
ylabel(ax, '$\left|T[u]\right|$');


fig = figure;
ax = axes(fig);
s = pcolor(T, Omega, Tomega2, 'Parent', ax);
set(s, 'EdgeColor', 'none');
xlabel(ax, '$t$');
ylabel(ax, '$\omega$');


%% test derivee psi

a1 = 1;
a2 = 20;
w1 = 6;
w2 = 6.5;
l1 = 0.9;
l2 = 0.95;
delta = 2;

dt = 0.001;
t = 0:dt:100;

psi = angle(a1*exp(-l1*t) + a2*exp(-l2*t + 1i*(w2-w1)*t + 1i*delta));

figure;
plot(t, psi);

dpsi = diff(psi);
dpsi = [dpsi(1), dpsi] + [dpsi, dpsi(end)] / dt;

figure;
plot(t, dpsi);


a = a2/a1;
w = w2-w1;
l = l2-l1;
theta = w*t+delta;

dpsi2 = a*exp(-l*t) .* (-l*sin(theta) + w*(a*exp(-l*t)+cos(theta))) ./ (1 + a^2*exp(-2*l*t) + 2*a*exp(-l*t).*cos(theta));

hold on
plot(t, dpsi2);



%% test fonction

a = linspace(0, 4, 100);
c = linspace(-1, 1, 100);
[a, c] = meshgrid(a, c);
F = (a + c)./(a + 1./a + 2*c);

figure;
surf(a, c, F);
xlabel('a');
ylabel('cos');





















