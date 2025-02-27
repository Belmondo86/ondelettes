function [x, v, a, xtmd, vtmd, atmd] = reponseTemporelleSystemeLineaire(x0, v0, t, mu, omega0, omega1, zeta0, zeta1)
%reponseTemporelleSystemeLineaire Summary of this function goes here
%   Detailed explanation goes here
lambda0 = omega0*zeta0;
lambda1 = omega1*zeta1;

M = diag([1, mu]);
C = 2*mu*[lambda0/mu + lambda1, -lambda1; -lambda1, lambda1];
K = mu*[omega0^2/mu + omega1^2, -omega1^2; -omega1^2, omega1^2];

Mat = [-M\C, -M\K; eye(2), zeros(2)];
[V, D] = eig(Mat);

X0 = [v0(1); v0(2); x0(1); x0(2)];
coeffs = V\X0;

x = zeros(size(t));
v = zeros(size(t));
a = zeros(size(t));
xtmd = zeros(size(t));
vtmd = zeros(size(t));
atmd = zeros(size(t));
for k=1:4
    x = x + coeffs(k)*V(3,k)*exp(D(k,k)*t);
    v = v + coeffs(k)*V(1,k)*exp(D(k,k)*t);
    a = a + D(k,k)*coeffs(k)*V(1,k)*exp(D(k,k)*t);
    xtmd = xtmd + coeffs(k)*V(4,k)*exp(D(k,k)*t);
    vtmd = vtmd + coeffs(k)*V(2,k)*exp(D(k,k)*t);
    atmd = atmd + D(k,k)*coeffs(k)*V(2,k)*exp(D(k,k)*t);
end

x = real(x);
v = real(v);
a = real(a);
xtmd = real(xtmd);
vtmd = real(vtmd);
atmd = real(atmd);

end

% 
% M = diag([1, mu]);
% C = 2*mu*[lambda0/mu + lambda1, -lambda1; -lambda1, lambda1];
% K = mu*[omega0^2/mu + omega1^2, -omega1^2; -omega1^2, omega1^2];
% 
% det(p^2*M+p*C+K)

% det
% mu*p^4
% + 2*lambda0*mu*p^3 + 2*lambda1*mu*p^3 + 2*lambda1*mu^2*p^3
% + mu*omega0^2*p^2 + mu*omega1^2*p^2 + mu^2*omega1^2*p^2 + 4*lambda0*lambda1*mu*p^2
% + 2*lambda0*mu*omega1^2*p + 2*lambda1*mu*omega0^2*p
% + mu*omega0^2*omega1^2


% d4 = 1;
% d3 = 2*lambda0 + 2*lambda1 + 2*lambda1*mu;
% d2 = omega0^2 + omega1^2 + mu*omega1^2 + 4*lambda0*lambda1;
% d1 = 2*lambda0*omega1^2 + 2*lambda1*omega0^2;
% d0 = omega0^2*omega1^2;
% 
% poly = [d4, d3, d2, d1, d0];
% poles = roots(poly);