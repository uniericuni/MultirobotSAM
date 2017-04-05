function robs = readData()

    addpath(fullfile('../data'));
    fprintf('initialization ...');
    rob0 = load('onboard-intel0-7000-28-01-04-14-30.mat');  % load data
    rob1 = load('onboard-intel1-7000-28-01-04-14-30.mat');
    rob2 = load('onboard-intel2-7000-28-01-04-14-30.mat');
    rob3 = load('onboard-intel3-7000-28-01-04-14-30.mat');
    robs = {rob0, rob1, rob2, rob3};
    
end