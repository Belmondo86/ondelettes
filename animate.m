function animate(object, t, x)
%animate Summary of this function goes here
%   Detailed explanation goes here
t = t-t(1);
N = length(t);

deltaT = 15;
dT = 0.04;
gamma = t(end)/deltaT;

X = zeros(0);

n = 1;
for T=0:dT:deltaT
    while n<N && t(n+1)<=gamma*T
        n = n+1;
    end
    if n>=N
        break
    end
    c = (gamma*T-t(n))/(t(n+1)-t(n));
    X(end+1) = 0.8*(x(n)*c+x(n+1)*(1-c));
end

fig = figure('Visible', 'on');
axis off;
ax = gca;
ax.Position = ax.OuterPosition;
hold(ax, 'on');
xlim([-0.5 0.5]);
ylim([-0.5 0.5]);
set(fig, 'WindowButtonDownFcn', @(~, ~) show());

p1 = plot(ax, 0, 0, 'o');

    function show()
        for el=X
            set (p1 , 'XData', 0.4*el);
            drawnow limitrate;
            pause(dT);
        end
    end

show();
end
