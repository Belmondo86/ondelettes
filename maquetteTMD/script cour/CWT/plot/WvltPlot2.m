function plt = WvltPlot2(t, freqs, wavelet, plotQuantity, Q, ctEdgeEffects)

if ~ismember(plotQuantity, {'module', 'arg', 'phase'})
    error('');
end


moduleScale = @(x) log(x);


%% figure

fig = figure;
ax = axes(fig);
hold(ax, 'on');

%% plot

[T, Freqs] = meshgrid(t, freqs);

if isequal(plotQuantity, 'module')
    wavelet = moduleScale(abs(wavelet));
    plt = pcolor(T, Freqs, wavelet);
    colormap(ax, jet);
elseif isequal(plotQuantity, 'arg') || isequal(plotQuantity, 'phase')
    wavelet = angle(wavelet);
    plt = pcolor(T, Freqs, wavelet);
    colormap(ax, hsv);
end

xlabel(ax, 'time')
ylabel(ax, 'frequency')
shading flat

%% zones d'effets de bord

if ctEdgeEffects>0
    deltat = ctEdgeEffects*Q./(2*pi*freqs); % = a * Delta t_psi, en considerant que 2*pi*Delta f_psi * Delta t_psi = 1/2
    
    t1 = t(1) + deltat;
    t2 = t(end) - deltat;
    
    % zone gris�e
    tEdge1 = [t1, t(1), t(1)];
    freqsEdge1 = [freqs, freqs(end), freqs(1)];
    
    tEdge2 = [t2, t(end), t(end)];
    freqsEdge2 = [freqs, freqs(end), freqs(1)];
    
    patch(tEdge1,freqsEdge1,'white','EdgeColor','none','FaceAlpha',.35);
    patch(tEdge2,freqsEdge2,'white','EdgeColor','none','FaceAlpha',.35);
    
    %ligne d�marcation
    plot(ax, t1, freqs, 'black--', 'LineWidth', 1.5);
    plot(ax, t2, freqs, 'black--', 'LineWidth', 1.5);
    
    % limites axes
    axis tight
end

end