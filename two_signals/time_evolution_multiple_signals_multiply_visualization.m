close all
clear all
% maxNumCompThreads(4);
% warning off
%% (1) input parameters
% lattice parameters
gz = 15;
N = gz^2;
a0 = 1.5;
rcell = 0.2;
Rcell = rcell*a0;

% circuit parameters
Con = [18 16];
Coff = [1 1];
M_int = [1 1; -1 -1];
K = [3 12; 13 20]; % K(i,j): sensitivity of type i to type j molecules
lambda = [1 1.2]; % diffusion length (normalize first to 1)
hill = Inf;
noise = 0;

% initial conditions
p0 = [0.2 0.6];
iniON = round(p0*N);
I0 = [0 0];
dI = 0.01;
InitiateI = 0; % 0: no, 1: yes

% generate cell_type (0 case type 1, 1 case type 2)
cell_type = zeros(N,1);

% simulation parameters
tmax = 10000;
nruns = 10;

% pos, dist
[dist, pos] = init_dist_hex(gz, gz);
%[pos,ex,ey] = init_cellpos_hex(gridsize,gridsize);
%dist = dist_mat(pos,gridsize,gridsize,ex,ey);

%{
fname_str = strrep(sprintf('N%d_iniON_%d_%d_M_int_%d_%d_%d_%d_a0_%.1f_Con_%d_%d_K_%d_%d_%d_%d_lambda_%.1f_%.1f', ...
    N, iniON(1), iniON(2), M_int(1,1), M_int(1,2), M_int(2,1), M_int(2,2), ...
    a0, Con(1), Con(2), K(1,1), K(1,2), K(2,1), K(2,2),...
    lambda(1), lambda(2)), '.', 'p');
%}
% check parameters
idx = (M_int == 0);
if ~all(K(idx)==0)
    fprintf('K has wrong entries! \n');
    warning('K has wrong entries!');
end

%}
%{
% TO DO: vectorize
dist_vec = a0*dist(1,:);
r = dist_vec(dist_vec>0); % exclude self influence
fN1 = sum(sinh(Rcell)*sum(exp((Rcell-r)./lambda(1)).*(lambda(1)./r)) ); % calculate signaling strength
fN2 = sum(sinh(Rcell)*sum(exp((Rcell-r)./lambda(2)).*(lambda(2)./r)) ); % calculate signaling strength

% nearest neighbour interaction strength
fprintf('activator fij(a0) = %.4f \n', sinh(Rcell)*sum(exp((Rcell-a0)./lambda(1)).*(lambda(1)./a0)))
fprintf('inhibitor fij(a0) = %.4f \n', sinh(Rcell)*sum(exp((Rcell-a0)./lambda(2)).*(lambda(2)./a0)))
%}

%% (2) Load parameters from saved trajectory
%{
% with parameters saved as structure array 
% load data
data_folder = 'H:\My Documents\Multicellular automaton\app\Multicellularity-2.1\data\time_evolution';
[file, path] = uigetfile(fullfile(data_folder, '\*.mat'), 'Load saved simulation');
load(fullfile(path, file));

s = save_consts_struct;
N = s.N;
a0 = s.a0;
K = s.K;
Con = s.Con;
Coff = s.Coff;
M_int = s.M_int;
hill = s.hill;
noise = s.noise;
rcell = s.rcell;
cells = cells_hist{1};
lambda = [1 s.lambda12];
%p0 = s.p_ini;
tmax =  s.tmax;
gz = sqrt(N);
Rcell = rcell*a0;
[dist, pos] = init_dist_hex(gz, gz);

% simulation parameters
%tmax = 100;
tmax = 10^4;
nruns = 10;
cell_type = zeros(N,1);
 
% Initial I
InitiateI = 0;
I0 = [0 0];
s_fields = fieldnames(s);
for i=1:numel(s_fields)
    if strcmp(s_fields{i},'I_ini_str')
        if ~isempty(s.I_ini_str)
            I0 = s.I_ini;
            InitiateI = 1;
        end
    end
end

%}
% Check whether loaded trajectory is same as simulation
%{
eq = 2*ones(numel(cells_hist_2), 1);
for i=1:numel(cells_hist_2)
    eq(i) = all(all(cells_hist{i} == cells_hist_2{i}));
end
%}
%% Simulate
cells_hist = {};
%t_out = 0;
%changed = 1;

% generate initial lattice
iniON = round(p0*N);
cells = zeros(N, 2);
for i=1:numel(iniON)
    cells(randperm(N,iniON(i)), i) = 1;
    if InitiateI && hill==Inf
        fprintf('Generating lattice with I%d(t=0)... \n', i);
        [cells_temp, test, I_ini] = generate_I_new(cells(:, i), I0(i), I0(i)+dI, dist, a0);
        cells(:,i) = cells_temp;
        fprintf('Generated initial I%d: %.2f; in range (Y=1/N=0)? %d; \n', i, I_ini, test);
    end
end

% store initial config
cells_hist{end+1} = cells; %{cells(:, 1), cells(:, 2)};

% dynamics
t = 0;
[cellsOut, changed] = update_cells_two_signals_multiply_finite_Hill(cells, dist, M_int, a0,...
        Rcell, Con, Coff, K, lambda, hill, noise);
while changed && t < tmax
    %pause(0.2);
    t = t+1;
    cells = cellsOut;
    cells_hist{end+1} = cells; %{cells(:, 1), cells(:, 2)};
    %update_cell_figure_continuum(app, pos, dist, a0, cells, app.Time, cell_type, disp_mol, 0);
    [cellsOut, changed] = update_cells_two_signals_multiply_finite_Hill(cells, dist, M_int, a0,...
        Rcell, Con, Coff, K, lambda, hill, noise);
end
t_out = t; % save final time

%% Analyze time step
probe_t = 0;
cells = cells_hist{probe_t+1};
cells2 = cells_hist{probe_t+2};

%%
% Account for self-influence
idx = dist>0;
% TO DO: vectorize / combine
M1 = ones(size(dist)); 
M1(idx) = sinh(Rcell)./(a0*dist(idx)/lambda(1))...
    .*exp((Rcell-a0*dist(idx))/lambda(1));
M2 = ones(size(dist)); 
M2(idx) = sinh(Rcell)./(a0*dist(idx)/lambda(2))...
    .*exp((Rcell-a0*dist(idx))/lambda(2));

% Concentration in each cell
C0 = Coff + (Con-Coff).*cells; 

% Reading of each cell
Y1 = M1*C0(:, 1); 
Y2 = M2*C0(:, 2);
Y = [Y1 Y2];

% Add noise to K
K_cells = K.*ones(2, 2, N); % NB inefficient code
dK = normrnd(0, noise, 2, 2, N);
K_cells = max(K_cells + dK, 1); % do not allow K < 1 = Coff

% Multiplicative interaction
if hill==Inf
    out11 = ((Y1-squeeze(K_cells(1,1,:)))*M_int(1,1) > 0) + (1 - abs(M_int(1,1)));
    out12 = ((Y2-squeeze(K_cells(1,2,:)))*M_int(1,2) > 0) + (1 - abs(M_int(1,2)));
    out21 = ((Y1-squeeze(K_cells(2,1,:)))*M_int(2,1) > 0) + (1 - abs(M_int(2,1)));
    out22 = ((Y2-squeeze(K_cells(2,2,:)))*M_int(2,2) > 0) + (1 - abs(M_int(2,2)));
    X1 = out11.*out12;
    X2 = out21.*out22;
elseif hill > 0
    %fX1 = (Y.^hill.*(1+M_int(1,:))/2 + (K(1,:).^hill.*(1-M_int(1,:))/2))...
    %    ./(K(1,:).^hill+Y.^hill).*abs(M_int(1,:)) + (1-abs(M_int(1,:))).*ones(N,2);
    %fX2 = (Y.^hill.*(1+M_int(2,:))/2 + (K(2,:).^hill.*(1-M_int(2,:))/2))...
    %    ./(K(2,:).^hill+Y.^hill).*abs(M_int(2,:)) + (1-abs(M_int(2,:))).*ones(N,2);
    fX1 = (Y.^hill.*(1+M_int(1,:))/2 + (squeeze(K_cells(1,:,:))'.^hill.*(1-M_int(1,:))/2))...
        ./(squeeze(K_cells(1,:,:))'.^hill+Y.^hill).*abs(M_int(1,:)) + (1-abs(M_int(1,:))).*ones(N,2);
    fX2 = (Y.^hill.*(1+M_int(2,:))/2 + (squeeze(K_cells(2,:,:))'.^hill.*(1-M_int(2,:))/2))...
        ./(squeeze(K_cells(2,:,:))'.^hill+Y.^hill).*abs(M_int(2,:)) + (1-abs(M_int(2,:))).*ones(N,2);
    X1 = prod(fX1, 2);
    X2 = prod(fX2, 2);
end

cells_out = [X1 X2];
changed = ~isequal(cells_out, cells);

disp( all(cells_out == cells2) )