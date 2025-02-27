function x = reponseSyst2ddl(t, f, w01, w02, zeta1, zeta2, C1, C2)
%REPONSESYST2DDL Syst�me lin�aire de degr� 2 avec amortissement
%proportionnel
%   Ck = (phik)^2/mk



%% equations
"z1'' + 2*zeta1*w01*z1' + w01^2*z1 = f * phi1/m1";
"z2'' + 2*zeta2*w02*z2' + w02^2*z2 = f * phi2/m2";
"x = phi1*z1 + phi2*z2";

H1 = @(freq) 1 ./ (-(2*pi*freq).^2 + 2i*zeta1*w01*2*pi*freq + w01^2);
H2 = @(freq) 1 ./ (-(2*pi*freq).^2 + 2i*zeta2*w02*2*pi*freq + w02^2);
H = @(freq) C1*H1(freq) + C2*H2(freq);

%% resolution
dt = mean(diff(t));
if max(abs(diff(t)-dt)/dt) > 1e-2
    error('pas de temps non constant');
end

TFf = fft(f);
freqs = (0:(length(t)-1)) / (t(end)-t(1));


TFx = TFf .* H(freqs);

x = ifft(TFx);
x = real(x);

end

