mu = 0.01;
omega0 = '2*pi';
omega1 = '2*pi';
zeta0 = 0;
epsilon = 1;
alpha = 1;

d2x0 = '-omega0^2*x0 - 2*omega0*zeta0*dx0 + mu*omega1^2*(x1-x0) + mu*epsilon*(d(alpha)x1-d(alpha)x0)';
d2x1 = '-omega1^2*(x1-x0)-epsilon*(d(alpha)x1-d(alpha)x0)';

T = 100;
nT = 200;
dt = 0.005;

x0 = [0; 0];
v0 = [1; 0];


waveletplots = systemeQuelconque({'x0', 'x1'}, {d2x0, d2x1}, {'mu', 'omega0', 'omega1', 'zeta0', 'epsilon', 'alpha'},...
    {mu, omega0, omega1, zeta0, epsilon, alpha},...
    x0, v0, true, 'T', T, 'nT', nT, 'dt', dt);


%ondelette
Q = 1;
MaxParallelRidges = 1;
fmin = 0.9;
fmax = 1.1;
NbFreq = 100;


WaveletMenu('WaveletPlot', waveletplots, 'fmin', fmin, 'fmax', fmax,...
    'NbFreq', NbFreq, 'Q', Q, 'MaxParallelRidges', MaxParallelRidges);


%regression
RegressionMenu;