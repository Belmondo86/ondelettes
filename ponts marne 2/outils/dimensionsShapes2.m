L = 74 + 2*(0.51+0.125);
l = 8 + 2*0;
D = 12;

sensorsPos = [
    L/2-2*D, 0 % 29277
    L/2-1*D, 0 % 29278
    L/2, 0     % 29279
    L/2+1*D, 0 % 29280
    L/2+2*D, 0 % 29281
    L/2+3*D, 0 % 29282
    L/2-3*D, l % 40195
    L/2-2*D, l % 40196
    L/2-1*D, l % 40197
    L/2, l     % 40198
    L/2+1*D, l % 40199
    L/2+2*D, l % 40200
    L/2+3*D, l % 40201
    L/2-3*D, 0 % 40202
    L/2, 0     % 29279, y axis
    ];

sensorsDir = [
    0, 0, 1 % 29277
    0, 0, 1 % 29278
    0, 0, 1 % 29279
    0, 0, 1 % 29280
    0, 0, 1 % 29281
    0, 0, 1 % 29282
    0, 0, 1 % 40195
    0, 0, 1 % 40196
    0, 0, 1 % 40197
    0, 0, 1 % 40198
    0, 0, 1 % 40199
    0, 0, 1 % 40200
    0, 0, 1 % 40201
    0, 0, 1 % 40202
    0, 1, 0 % 40202
    ];

shapePlotBridge = @(shape, figTitle) shapePlotPlate2([L, l], sensorsPos, sensorsDir, shape, figTitle);
shapePlotBridge = @(shape, figTitle) shapePontsMarne([L, l], sensorsPos, sensorsDir, shape, figTitle);
shapePlotBridgeAnim = @(shape, figTitle) shapePlotPlateAnimated2([L, l], sensorsPos, sensorsDir, shape, figTitle);


%% test

% shapePlotBridge([1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], 'test');