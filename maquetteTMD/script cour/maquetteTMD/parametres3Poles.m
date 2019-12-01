
% fonction de diff�rence entre les poles trouv�s avec la transform�e en
% ondelettes et les poles th�oriques pour certains param�tres
S = @(param) abs(poles - getPoles3ddl(param(1), param(2), param(3), param(4), param(5), param(6)));


f10 = nan; % � compl�ter
f20 = nan; % � compl�ter
mu10 = nan; % � compl�ter
mu20 = nan; % � compl�ter
ft0 = nan; % � compl�ter
zetat0 = nan; % � compl�ter


param0 = [f10, f20, mu10, mu20, ft0, zetat0];


param0 = [6.7, 5.7, 0.015, 0.015, 6.7, 0.07];




% r�gression permettant de trouver les param�tres minimisant la diff�rence
% entre poles exp�rimentaux et th�oriques
optionsReg = optimoptions(@lsqnonlin, 'MaxIterations', 1e5,...
    'StepTolerance', 1e-6, 'MaxFunctionEvaluations', inf, 'FunctionTolerance', 0);
lbound = zeros(1, 6);
ubound = inf*ones(1, 6);

param = lsqnonlin(S, param0, lbound, ubound, optionsReg);



f1 = param(1);
f2 = param(2);
mu1 = param(3);
mu2 = param(4);
ft = param(5);
zetat = param(6);


% affichage des r�sultats
disp(['f1 = ', num2str(f1)]);
disp(['f2 = ', num2str(f2)]);
disp(['ft = ', num2str(ft)]);
disp(['zetat = ', num2str(100*zetat), ' %']);
disp(['mu1 = ', num2str(100*mu1), ' %']);
disp(['mu2 = ', num2str(100*mu2), ' %']);
