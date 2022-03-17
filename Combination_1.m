clear all;
clc
tic

%% DATA LOADING AND REFINEMENT
[num,txt,raw] = xlsread('Tainan_in_2015.xls');
t1 = datetime(2015,1,1,'Format','yyyy/MM/dd');
t2 = datetime(2015,12,31,'Format','yyyy/MM/dd');
t = t1:t2;
m = datestr(t,'yyyy/mm/dd');

for i=1:365
    loc = strcmp(raw(:,1),m(i,:));
    logpm25 = strcmp(raw(:,2),'PM2.5');
    logtemp = strcmp(raw(:,2),'AMB_TEMP');
    logdir = strcmp(raw(:,2),'WIND_DIREC');
    logspe = strcmp(raw(:,2),'WIND_SPEED');
    logrh = strcmp(raw(:,2),'RH');

    % attributes at one date 
    log1 = loc.*logpm25;
    log2 = loc.*logtemp;
    log3 = loc.*logdir;
    log4 = loc.*logspe;
    log5 = loc.*logrh;

    % Find index for logs = 1 or other logs = 1
    locc1 = find(log1==1); 
    locc2 = find(log2==1); 
    locc3 = find(log3==1); 
    locc4 = find(log4==1); 
    locc5 = find(log5==1); 

    % check two attributes exist at one date  
    TF = (5-(isempty(locc1)+isempty(locc2)+isempty(locc3)+isempty(locc4)));

    if (TF==5)
        datpm25(i,:) = num(locc1,:);
        dattemp(i,:) = num(locc2,:);
        datdir(i,:) = num(locc3,:);
        datspe(i,:) = num(locc4,:);
        datrh(i,:) = num(locc5,:);
    end
end

% reshape
Data(:,1) = reshape(datpm25',365*24,[]); %PM25
Data(:,2) = reshape(dattemp',365*24,[]); %TEMP
Data(:,3) = reshape(datdir',365*24,[]);  %DIRE
Data(:,4) = reshape(datspe',365*24,[]);  %SPEE
Data(:,5) = reshape(datrh',365*24,[]);   %RH

% Plus n hour(s)
n = 1;

% Deviding
mm = 1;
for i = 1:365*24-n
    NanValue1 = isnan(Data(i,:)); NanValue2 = isnan(Data(i+n,:));
    if (sum(NanValue1)==0 && sum(NanValue2)==0)
        % Filtered Data without Nan
        data(mm,:) = Data(i,:);
        data2(mm,:) = Data(i+n,:);
        time(mm) = i;
        mm = mm+1;
    end
end

% Inputs(t) 
inputs = data(:,5); % Input for Neural Network [1,2,3,4,5]
% Target PM(t+n)
target = data2(:,1); % Target for Neural Network

%% NEURAL NETWORK
% load and building networks
net = newff(inputs',target',[10 10], {'tansig','tansig','purelin'});

% The network is trained for 200 epochs. Again the network's output is plotted.
net.trainparam.epochs = 200;

% Training/Testing/Validation Ratio
net.divideParam.trainRatio = 0.6;   % set proportion of data for training
net.divideParam.valRatio = 0.2;     % set proportion of data for validation
net.divideParam.testRatio = 0.2;    % set proportion of data for testing 

% train (net, input, target)
net = train(net,inputs',target');

toc