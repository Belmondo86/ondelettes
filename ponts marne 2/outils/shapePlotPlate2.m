function fig = shapePlotPlate2(plateDim, dofPos, dofDir, shape, figTitle)
%COMPLEXSHAPEPLOTDEFAULT Summary of this function goes here
%   Detailed explanation goes here

displayChannelNb = false;

if nargin < 4
    warning('shape mising');
    plateDim = [3, 1];
    dofPos = rand(5, 2) .* plateDim;
    dofDir = rand(5, 3);
    shape = randn(1, 5);
end

if nargin < 5
    figTitle = '';
end

%%

if length(shape) ~= size(dofPos, 1)
    warning(sprintf('Mode shape dimensions: %u (%u expected)', [length(shape), size(dofPos, 1)]));
end

%%
n = length(shape);

shape = 0.12 * max(plateDim)/max(abs(shape)) * shape;

fig = figure('Name', figTitle);
set(fig, 'Position', get(fig, 'Position') .* [1 1 1.2 0.9]);
ax = axes(fig);
hold(ax, 'on');
% legend(ax, 'AutoUpdate' ,'off');

% plate
Xplate = [0, 0; plateDim(1), plateDim(1)];
Yplate = [0, plateDim(2); 0, plateDim(2)];
Zplate = zeros(2);

surf(ax, Xplate, Yplate, Zplate, 'EdgeColor', 'black', 'FaceColor', 0.5*[1 1 1], 'FaceAlpha', 0.5);


% dof
arrows = nan(1, n);
drawShape();


% legendNames = {};
% for k = 1:length(shape)
%     legendNames{end+1} = ['dof', num2str(k)];
% end
% 
% legend(ax, legendNames);



view(ax, -30, 20);

daspect(ax, [1 1 1]);
set(ax, 'PositionConstraint', 'innerposition');
set(ax, 'XLim', [0, plateDim(1)]);
set(ax, 'YLim', [0, plateDim(2)]);
set(ax, 'ZLim', max(plateDim)*0.2*[-1 1]);
set(ax, 'Clipping', 'off');
% pbaspect(ax, [plateDim, 0.3*max(plateDim)]);
set(ax,'visible','off');
set(ax, 'InnerPosition', [0.02 0.02 0.96 0.96]);

% lightangle(ax, -70, 5);
% lighting gouraud
% lighting flat

%% inversion sens

    function shapeInv()
        shape = -shape;
        delete(arrows);
        drawShape();
    end

fig.WindowButtonDownFcn = @(~,~) shapeInv();

%% 

    function drawShape()
        for k = 1:n
            X = dofPos(k, 1) * [1 1];
            Y = dofPos(k, 2) * [1 1];
            Z = [0 0];
            X = X + shape(k) * [0, dofDir(k, 1)];
            Y = Y + shape(k) * [0, dofDir(k, 2)];
            Z = Z + shape(k) * [0, dofDir(k, 3)];
            
            dofColorVert = 0.8 * [1 0 0];
            dofColorHor = 0.8*[0 0 1];
            if k < n
                dofColor = dofColorVert;
            else
                dofColor = dofColorHor;
            end
            
            arrows(k) = mArrow3(ax, [X(1), Y(1), Z(1)], [X(2), Y(2), Z(2)], 'color', dofColor, 'stemWidth', min(plateDim)/20);
            
            if displayChannelNb
                %text(ax, X(2), Y(2), Z(2) + 0.1*sign(shape(k))*max(abs(shape)), ['', num2str(k)]);
                text(ax, X(1), Y(1), Z(1), [' ch', num2str(k)]);
            end
        end
    end

end

