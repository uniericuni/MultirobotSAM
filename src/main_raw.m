% ==================================================================
% EECS568
%
% H_MAP, W_MAP: height and width of maps
% UPDATE_PERIOD: perioud of A update
% N: number of robots
% T: total step number
% A: adjacency matrix
% b: residual vector, 3N*(t+2) x 1
% x: state matrix, 3N x (t+2)
% t: current steps
% priors: N*1 float
% init_poses: 3N*1
% map: map, Hx W x 3 | 3: for current likelihood, robot index, step
% control: control signal
% observation: observation signal
% ==================================================================

% =====================
% Initialization
% =====================
close all;
clear;
clc;

% Initialize globals
global INFO;                            % experiment configuration, should not be updated
global PARAM;                           % global variables, should be updated
addpath('../lib');                      % add data structure library

% INFO
INFO.grid_size = 0.2;                   % gird size for grid map
INFO.mapSize = 140 * 1/INFO.grid_size;  % grid map size
INFO.robs = readData();                 % robot data
INFO.N = length(INFO.robs);             % robot number
INFO.COST_MAX = INFO.grid_size*20;      % minimum acceptable score for contour
INFO.GLOBAL_BUFF_SIZE = 500;            % buffer size for global map history
INFO.Sigma_v = 0.001;                   % velocity control uncertainty
INFO.Sigma_omega = 0.001;               % omega control uncertainty
INFO.Q = diag([0.001,0.001,0.1/180*pi].^2); % Observation covariance
INFO.Default_var = 1e-5;             % Prevent Singularity

% PARAM
PARAM.map = zeros(INFO.mapSize*2+1,...  % grid map
    INFO.mapSize*2+1);
PARAM.local_buff = struct();
PARAM.local_buff.map = PARAM.map(:,:);  % create local buffer
PARAM.local_buff.pose_col = 0;
PARAM.local_buff.robot_id = 0;
PARAM.buff_size = 0;
PARAM.obs_buff = ...                    % observer to map buffer
    cell(INFO.GLOBAL_BUFF_SIZE);
PARAM.pose_id = ones(1,INFO.N);         % current pose id for each robot
PARAM.laser_id = ones(1,INFO.N);        % current laser(sensor) id for each robot
PARAM.prev_time = zeros(1,INFO.N);      % time of previous state
PARAM.prev_pose = zeros(3,INFO.N);      % pose of previous state

% initialize A,b,x
[A, b, x] = initialize_Abx();
[R,d] = sparse_factorization(A,b);

%mega_obs = [];
%mega_robidControl = [];
%mega_robidObs = [];
%mega_controls = [];

% =====================
% Main Loop
% =====================
c = 0;
cc = 0;
xs = [];
while true
    
    % parsing controls and observation
    c = c+1;
    [rob_id, controls, poses, pred_pose, observation, time] = parser();
    if ~(size(controls,2)==0 )
        cc = cc+1;
        x = update_state(x,poses,rob_id, time );
    else
        continue;
    end
    
    %{
    % merge map
    extractNewMap(observation, pred_pose, size(x,2), rob_id(end));
    if mod(cc, 100)==99
        
        % merge with global map
        g_map = PARAM.map;
        l_map = PARAM.local_buff.map;
        g_map(g_map==0) = l_map(g_map==0);
        g_map(g_map>0) = max(g_map(g_map>0),l_map(g_map>0));
        g_map(g_map<0) = min(g_map(g_map<0),l_map(g_map<0));
        
        % dafd
        PARAM.map = g_map;
        
        % push local buffer to global buffer
        PARAM.buff_size = PARAM.buff_size+1;
        if PARAM.buff_size > INFO.GLOBAL_BUFF_SIZE
            PARAM.obs_buff{1:end-1} = PARAM.obs_buff{2:end};
            PARAM.buff_size = PARAM.buff_size - 1;
        end
        obs = PARAM.local_buff;
        obs.map = PARAM.map;
        PARAM.obs_buff{PARAM.buff_size} = obs;
        PARAM.local_buff.map = zeros(INFO.mapSize*2+1,...
            INFO.mapSize*2+1);
        PARAM.local_buff.pose_col = 0;
        PARAM.local_buff.robot_id = 0;
        fprintf(['\niteration: ', num2str(c)]);
        
        % cache current record
        temp_buff = PARAM.obs_buff;
        save('cache.mat', 'x', 'temp_buff');
    end
    %}
end
