function [initWaitBar, updateWaitBar, closeWaitBar] = getWaitBar(N, varargin)
%GETWAITBAR Summary of this function goes here
%   Detailed explanation goes here

p = inputParser ;
%% parametres par defaut
displayTimeDef = 0;
windowTitleDef = '';
msgDef = '';
printProgressDef = true;
progressStringFcnDef = @(k) sprintf('%d%%', round(100*k/N));
printTimeRemainingDef = true;
minimumBeepTimeDef = inf;
updateFreqDef = 5;
printMsgDef = false;

update_waitbar_time = 0.1;
update_remainingTime_time = 2;

%
addParameter(p,'displayTime', displayTimeDef);
addParameter(p,'windowTitle', windowTitleDef);
addParameter(p,'msg', msgDef);
addParameter(p,'printProgress', printProgressDef);
addParameter(p,'progressStringFcn', progressStringFcnDef);
addParameter(p,'printTimeRemaining', printTimeRemainingDef);
addParameter(p,'minimumBeepTime', minimumBeepTimeDef);
addParameter(p,'updateFreq', updateFreqDef);
addParameter(p,'printMsg', printMsgDef);

%
parse(p, varargin{:});

displayTime = p.Results.displayTime;
windowTitle = p.Results.windowTitle;
windowTitle2 = windowTitle;
msg = p.Results.msg;
printProgress = p.Results.printProgress;
progressStringFcn = p.Results.progressStringFcn;
printTimeRemaining = p.Results.printTimeRemaining;
minimumBeepTime = p.Results.minimumBeepTime;
updateFreq = p.Results.updateFreq;
printMsg = p.Results.printMsg;

%%

waitBarObj = [];
waitBarObjCreated = false;
K = nan;
t0 = nan;
tlast = nan;
time_rem = nan;
tlast_time_rem = nan;
Klast_time_rem = nan;
I_update_freq = floor(24*3600*now*updateFreq);


    function timeS = timeRemainingString(t)
        [h, m, s] = hms(seconds(t));
        if t >= 10
            s = 10*floor(s/10);
        else
            s = floor(s);
        end
        if h == 0 && m == 0
            timeS = sprintf('%ds', s);
        elseif h == 0 && m < 5 && s ~= 0
            timeS = sprintf('%dm%02ds', [m, s]);
        elseif h == 0
            timeS = sprintf('%dm', m);
        else
            timeS = sprintf('%dh%02dm', [h, m]);
        end
    end

    function s = msgString()
        s = msg;
        if printProgress && ~isnan(K)
            if ~isempty(s)
                s = [s, ', ', progressStringFcn(K)];
            else
                s = progressStringFcn(K);
            end
        end
        if printTimeRemaining && ~isnan(time_rem)
            if ~isempty(windowTitle)
                windowTitle2 = [windowTitle, ' (', timeRemainingString(time_rem), '...)'];
            else
                windowTitle2 = [timeRemainingString(time_rem), '...'];
            end
        end
    end

    function updateProgress()
        if ~isempty(waitBarObj) && ~isvalid(waitBarObj)
            return
        end
        
        t = 24*3600*now;
        if t - tlast < update_waitbar_time
            return
        end
        
        % progress
        tlast = t;
        
        % waittime
        if t - tlast_time_rem >= update_remainingTime_time
            if ~isnan(Klast_time_rem)
                time_rem = (t - tlast_time_rem) /(K - Klast_time_rem) *(N - K);
            end
            tlast_time_rem = t;
            Klast_time_rem = K;
        end
        
        % display
        if ~isempty(waitBarObj)
            try
                waitbar(K/N, waitBarObj, msgString());
                set(waitBarObj, 'Name', windowTitle2);
                drawnow
            catch
            end
        end
        
        % print
        if printMsg
            disp([msgString(), ' (', timeRemainingString(time_rem), '...)']);
        end
    end

%%

    function createWB()
        if isnan(K)
            x = 0;
        else
            x = K/N;
        end
        waitBarObj = waitbar(x, msgString(), 'Name', windowTitle);
        waitBarObjCreated = true;
    end

    function initWaitBar0(k)
        if nargin == 0
            k = 0;
        end
        
        t = 24*3600*now;
        % init
        t0 = t;
        % progress
        tlast = t;
        % waittime
        tlast_time_rem = t;
        % k
        K = k;
        
        if displayTime <= 0
            createWB()
        end
    end

    function updateWaitBar0(k, new_msg)
        if nargin < 2 && floor(24*3600*now*updateFreq) <= I_update_freq
            return
        else
            I_update_freq = floor(24*3600*now*updateFreq);
        end
        if nargin == 0
            k = K+1;
        elseif isnan(k)
            k = K;
        end
        K = k;
        if  ~waitBarObjCreated && 24*3600*now - t0 >= displayTime
            createWB()
        end
        if nargin >= 2
            msg = new_msg;
        end
        updateProgress();
    end

    function closeWaitBar0()
        if 24*3600*now - t0 >= minimumBeepTime
            beep
        end
        delete(waitBarObj);
    end

initWaitBar = @initWaitBar0;
updateWaitBar = @updateWaitBar0;
closeWaitBar = @closeWaitBar0;

end

