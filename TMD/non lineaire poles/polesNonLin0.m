function polesNonLin0()
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

mu = 0.01;
omega0 = '2*pi';
omega1 = '2*pi';
zeta0 = 0;
epsilon = 0.4;
alpha = 0;

T = 100;
nT = 2000;

x0 = [0; 0];
v0 = [1; 0];


%%
w0 = eval(omega0);
w1 = eval(omega1);

wa2 = -(w0^2+(1+mu)*w1^2)/2 - 1/2*sqrt(w0^4+(1+mu)^2*w1^4+2*(1+mu)*w0^2*w1^2-4*w0^2*w1^2);
wb2 = -(w0^2+(1+mu)*w1^2)/2 + 1/2*sqrt(w0^4+(1+mu)^2*w1^4+2*(1+mu)*w0^2*w1^2-4*w0^2*w1^2);
wa = sqrt(wa2);
wb = sqrt(wb2);
deformA0 = -wa2/(wa2+w1^2);
deformB0 = -wb2/(wb2+w1^2);
deformA0 = -(w0^2+(1+mu)*wa2)/(mu*wa2);
deformB0 = -(w0^2+(1+mu)*wb2)/(mu*wb2);


phi0 = log((deformB0*v0(1)+v0(2))/(wa*(deformA0-deformB0)) * 1i);
psi0 = log((deformA0*v0(1)+v0(2))/(wb*(deformA0-deformB0)) * 1i);

% dphi = wa;
% dpsi = wb;


    function dphidpsi = dPhidPsi(phiPsi, dphidpsi, deforms)
        phi = phiPsi(1);
        psi = phiPsi(2);
        dphi = dphidpsi(1);
        dpsi = dphidpsi(2);
        deformA = deforms(1);
        deformB = deforms(2);
        
        Ca = epsilon*2*1i/pi^2*exp(-real(phi))*deformA/abs(deformA)...
            * I0(abs(imag(dpsi)/imag(dphi)*exp(psi-phi)*deformB/deformA));
        Cb = epsilon*2*1i/pi^2*exp(-real(psi))*deformB/abs(deformB)...
            * I0(abs(imag(dphi)/imag(dpsi)*exp(phi-psi)*deformA/deformB));
        
        dphi2 = -(w0^2+(1+mu)*w1^2-mu*Ca)/2 - 1/2*sqrt((w0^2+(1+mu)*w1^2-mu*Ca)^2-4*w0^2*w1^2);
        dpsi2 = -(w0^2+(1+mu)*w1^2-mu*Cb)/2 + 1/2*sqrt((w0^2+(1+mu)*w1^2-mu*Cb)^2-4*w0^2*w1^2);
        
        
        dphi = - sqrt(dphi2);
        dpsi = - sqrt(dpsi2);
%         dphi = (2*(real(dphi)<=0)-1) * dphi;
%         dpsi = (2*(real(dpsi)<=0)-1) * dpsi;
        dphi = (2*(imag(dphi)>=0)-1) * dphi;
        dpsi = (2*(imag(dpsi)>=0)-1) * dpsi;
        
%         dphi = dphi - max(real(dphi),0);
%         dpsi = dpsi - max(real(dpsi),0);
        
        dphidpsi = [dphi, dpsi];
    end


    function I = I0(lambda)
        k2 = 4*lambda/(lambda+1)^2;
        if k2 >= 1
            I = 4;
            return
        end
        [K,E] = ellipke(k2);
        I = 2*(lambda+1)*E - 2*(lambda-1)*K;
        
%         theta = linspace(0, 2*pi, 1000);
%         theta = theta(1:end-1);
%         I = (1 + lambda^2 + 2*lambda*cos(theta)).^(-1/2) .* (1 + lambda*cos(theta));
%         I = sum(I)*(theta(2)-theta(1));

%         I = 2*pi * (1+lambda^2).^(-1/2) * (1 + -1/2*lambda^2/(1+lambda^2));

%         I = 4;

%         I = 0;
    end


% [tout, Anglesout] = ode45(@dPhidPsi, [0 T], [phi0; psi0],...
%     odeset('RelTol', 1e-10, 'Stats', 'off', 'MaxStep', 1/nT));


dt = 1/nT;

tout = 0:dt:T;
dAnglesout = nan(length(tout), 2);
dAnglesout(1,:) = [wa, wb];
Anglesout = nan(length(tout), 2);
Anglesout(1,:) = [phi0, psi0];
Deforms = nan(length(tout), 2);
Deforms(1,:) = [deformA0, deformB0];

for k = 2:length(tout)
    if k == 2
        dAnglesout(k-1,:) = dPhidPsi(Anglesout(k-1,:), dAnglesout(k-1,:), Deforms(k-1,:));
    end
    Anglesout(k,:) = Anglesout(k-1,:) + dt*dAnglesout(k-1,:);
    Deforms(k,:) = - (w0^2 + (1+mu)*dAnglesout(k-1,:).^2) ./ (mu*dAnglesout(k-1,:).^2);
    
    dAnglesout(k,:) = dPhidPsi(Anglesout(k,:), dAnglesout(k-1,:), Deforms(k,:));
    Anglesout(k,:) = Anglesout(k-1,:) + dt*(dAnglesout(k-1,:)+dAnglesout(k,:))/2;
    Deforms(k,:) = - (w0^2 + (1+mu)*dAnglesout(k,:).^2) ./ (mu*dAnglesout(k,:).^2);
end

fig = figure;
ax = axes(fig);
plot(tout, imag(dAnglesout)/(2*pi), 'Parent', ax);
ylim(ax, [0, 2]);

fig = figure;
ax = axes(fig);
plot(tout, real(dAnglesout), 'Parent', ax);
ylim(ax, [-1, 1]);

fig = figure;
ax = axes(fig);
plot(tout, exp(real(Anglesout)), 'Parent', ax);

fig = figure;
ax = axes(fig);
plot(tout, angle(Deforms), 'Parent', ax);

fig = figure;
ax = axes(fig);
plot(tout, abs(Deforms), 'Parent', ax);

coefficient = (1 + Deforms - w1^2/w0^2*Deforms*(1+mu) - w1^2/w0^2*mu*Deforms.^2) .* dAnglesout.^2 ./ (1i*Deforms);

fig = figure;
ax = axes(fig);
plot(tout, coefficient, 'Parent', ax);


















%% integration classique
% d2x0 = '-omega0^2*x0 - 2*omega0*zeta0*dx0 + mu*omega1^2*(x1-x0) + mu*epsilon*sign(dx1-dx0)*abs(dx1-dx0)^alpha';
% d2x1 = '-omega1^2*(x1-x0)-epsilon*sign(dx1-dx0)*abs(dx1-dx0)^alpha';
% 
% waveletplots = systemeQuelconque({'x0', 'x1'}, {d2x0, d2x1}, {'mu', 'omega0', 'omega1', 'zeta0', 'epsilon', 'alpha'},...
%     {mu, omega0, omega1, zeta0, epsilon, alpha},...
%     x0, v0, false, 'T', T, 'nT', nT);
% 
% 
% %ondelette
% Q = 1;
% MaxParallelRidges = 1;
% fmin = 0.9;
% fmax = 1.1;
% NbFreq = 100;
% 
% 
% WaveletMenu('WaveletPlot', waveletplots, 'fmin', fmin, 'fmax', fmax,...
%     'NbFreq', NbFreq, 'Q', Q, 'MaxParallelRidges', MaxParallelRidges);
% 
% 
% %regression
% RegressionMenu;



end

