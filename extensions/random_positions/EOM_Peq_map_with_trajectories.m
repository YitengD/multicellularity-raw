%% Plots a map of Peq in p, I space
% Plot trajectories (simulated, Langevin) on top of it
clear all
close all
clc
warning off
%% Parameters
% geometric parameters
Lx = 1;
n = 12; % nmax = L/R (square packing)
rcell = 0.2;
ini_alg = 0; % 1: Markov MC, 0: random placement
mcsteps = 10^4; % for Markov MC
N = n^2;

% Circuit Parameters
K = 16;
Con = 8;
noise = 0;
a0 = 0.5; 
Rcell = rcell*a0;

%Klist = [3 6 10 15 17 20]; %(a0=1.5) [3 6 10 15 17 20]; % (a0=0.5) [10 10 14 19 16 18]; %[3]; 
%Conlist = [24 21 21 20 14 14]; %(a0=1.5) [24 21 21 20 14 14]; % (a0=0.5) [5 21 16 14 8 6]; %[24];

% load fN, gN (for perfect lattice)
[dist, pos] = init_dist_hex(n, n);
dist_vec = dist(1,:);
r = a0*dist_vec(dist_vec>0); % exclude self influence
fN = sum(sinh(Rcell)*sum(exp(Rcell-r)./r)); % calculate signaling strengthN
gN = sum(sum((sinh(Rcell)*exp(Rcell-r)./r).^2)); % calculate signaling strength

% --------For loop K, Con--------------
%for idx=1:numel(Klist)
idx = 1;
%K = Klist(idx);
%Con = Conlist(idx);
 
% Calculate delta, sigma (of EOM)
[delta, sigma] = EOM_calc_delta_sigma(N, K, Con, fN, gN);
%% Calculate P_eq
p = (0:N)/N;
I = linspace(-0.15, 1, 2*116);
[pm, Im] = meshgrid(p,I);

muon = fN*(Con.*pm + 1 - pm + (Con-1).*(1-pm).*Im);
muoff = fN*(Con.*pm + 1 - pm - (Con-1).*pm.*Im);
kappa = sqrt((Con-1)^2*(gN)*pm.*(1-pm));
sigmaon = kappa;
sigmaoff = kappa;

zon = (K - Con - muon)./sigmaon;
zoff = (K - 1 - muoff)./sigmaoff;

Poffoff = normcdf(zoff);
Ponon = 1-normcdf(zon);

pe = (Ponon.^pm .* Poffoff.^(1-pm)).^N;
%% Plot result
h=figure(idx);
imagesc(p, I, pe);
set(gca, 'YDir', 'Normal');
c = colorbar;
xlabel('p');
ylabel('I');
ylabel(c, 'P_{eq}');
caxis([0 1]);
set(gca, 'FontSize', 24);
set(gcf, 'Units','Inches', 'Position', [0 0 10 8]);

%% Plot gradient vector field
% Multiplicative noise in drift of I
%
%{
% old approach (only N)
Ns = 6^2; %optimal N
fmax = 5; %max amplification
a = Ns*log(fmax);
f = fmax.*exp(-a./N);
f = 1;
%}

% Load fitted surface phi(N, a0)
%fname = 'H:\My Documents\Multicellular automaton\rebuttal\I_correction\I_correction_phi_N_a0_K6_Con15.mat';
%load(fname, 'f');
%phi = f(gridsize, a0);
% phi = maxI Langevin / maxI simulation
% In update rule below, enter 1/phi instead of phi!

% define gradient
delh_delp = @(p,I) (Con-1)*2*fN*(I-1).*(2*p - 1) -(Con+1)*(fN+1)+2*K;
delh_delI = @(p,I) 2*fN*(Con - 1)*p.*(p - 1);

figure(h);
hold on
pv = (0:n:N)/N;
Iv = -0.15:0.08:1;
[pm2, Im2] = meshgrid(pv, Iv);
vf_x = -delh_delp(pm2, Im2);
vf_y = -delh_delI(pm2, Im2);
quiver(pm2, Im2, vf_x, vf_y, 'LineWidth', 1, 'AutoScaleFactor', 1.2,...
    'Color', [0.5 0.5 0.5]);
%}
%% Load simulated trajectories (cellular automaton)
%----Settings--------------------------------------------------------------
% p values of trajectories to plot
p_ini = 0:0.1:1; %(0:5:N)/N;

% load all files from a folder
path = 'H:\My Documents\Multicellular automaton\data\random_positions';
straux = '(\d+)';
labels = {'RandomPlacement', sprintf('MarkovMC_%d_MCsteps', mcsteps)};
choice = 1; %choice of label (randomization procedure)  
%--------------------------------------------------------------------------
listing = dir(path);
num_files = numel(listing)-2; %first two entries are not useful
% variables 
I_ini = zeros(numel(p_ini), 1);
p_out = zeros(numel(p_ini), 1); % store p_out values
eq_times1 = zeros(numel(p_ini), 1);

nruns = 0;
for idx_p = 1:numel(p_ini)
    p = p_ini(idx_p);
    
    % filename pattern (regexp notation)
    fpattern = strrep(sprintf('N%d_Lx%.2f_a0_%.2f_K%d_Con%d_n%d_%s-v%s', N, Lx,...
            a0, K, Con, round(p*N), labels{choice}, straux), '.', 'p');
    %fpattern = strrep(sprintf('N%d_Lx%.2f_n%d_%s-v%s', N, Lx,...
    %     round(p*N), labels{1}, straux), '.', 'p');

    for i = 1:num_files
        filename = listing(i+2).name;
        % remove extension and do not include txt files
        [~,name,ext] = fileparts(filename);
        if strcmp(ext, '.mat')
            [tokens, ~] = regexp(name, fpattern, 'tokens', 'match');
            if numel(tokens) > 0
                disp(name);
                nruns = nruns + 1;
                %names{nruns} = name;
                load(fullfile(path, name), 'cells_hist', 'dist', 'a0_new', 't');

                Non = zeros(t+1, 1);
                I = zeros(t+1, 1);
                for tau=1:t+1
                    Non(tau) = sum(cells_hist{tau});
                    I(tau) = moranI(cells_hist{tau}, a0*dist);
                end
                
                % save initial I
                %I_ini(k) = I(1);
                %p_out(k) = Non(end)/N;
                %eq_times1(k) = numel(Non) - 1;
                
                % Plot trajectory
                figure(h);
                hold on
                plot_sim = plot(Non/N, I, 'r-', 'LineWidth', 1.5);
                plot(Non(1)/N, I(1), 'ro', 'LineWidth', 2);
                plot(Non(end)/N, I(end), 'rx', 'LineWidth', 2);
                plot_sim.Color(4) = 1; % transparency
            end
        end
    end
end

%% New Langevin equation 
%{
% define gradient
delh_delp = @(p,I) (Con-1)*2*fN*(I-1).*(2*p - 1) -(Con+1)*(fN+1)+2*K;
delh_delI = @(p,I) 2*fN*(Con - 1)*p.*(p - 1);

% trajectory variables
maxsteps = 100;
p_stoch = zeros(nruns, maxsteps+1);
I_stoch = zeros(nruns, maxsteps+1);
pnoise = zeros(nruns, maxsteps+1);
Inoise = zeros(nruns, maxsteps+1);
eq_times2 = zeros(nruns, 1);

% If plotting multiple trajectories from same p_ini
%test = reshape(repmat(round(N*p_ini)/N, [10 1]), [30 1]);
%I_ini = 0;

pnoise(:,1) = 0;
Inoise(:,1) = 0; %normrnd(0, 0.02, [nruns, 1]); % take larger noise for initial spread
p_stoch(:,1) = p_ini' + pnoise(:,1);
%p_stoch(:,1) = test;
I_stoch(:,1) = I_ini + Inoise(:,1);

Peq_all = zeros(nruns, maxsteps);
for i=1:nruns
    for j=1:maxsteps 
        pt = p_stoch(i, j);
        It = I_stoch(i, j);
        [p_new, I_new, Peq, p_lim] = EOM_update_Langevin(pt, It, N, Con, K, fN, gN, delta, sigma, 0);
        Peq_all(i,j) = Peq;
        
        % system out of range?
        if p_lim == 1 || p_lim == -1
            p_stoch(i, j+1:end) = (p_lim+1)/2;
            I_stoch(i, j+1:end) = 0;
        end
        
        % system in equilibrium?
        if rand < Peq
            eq_times2(i) = j-1;
            p_stoch(i, j+1:end) = pt;
            I_stoch(i, j+1:end) = It;
            break
        else
            p_stoch(i, j+1) = p_new;
            I_stoch(i, j+1) = I_new;
        end
    end
end

% Plot Langevin trajectories
figure(h);
hold on
%h1a = plot(p_stoch', I_stoch', 'g-', 'LineWidth', 1.5);
handles = cell(numel(p_ini), 1);
for pl=1:nruns
    handles{pl} = plot(p_stoch(pl,:)', I_stoch(pl,:)', 'g-', 'LineWidth', 2);
    handles{pl}.Color(4) = 0.6;
end   

% plot start and end points
plot(p_stoch(:,1), I_stoch(:,1), 'go', 'LineWidth', 2);
plot(p_stoch(:,end), I_stoch(:,end), 'gx', 'LineWidth', 2);

%% set figure properties
set(gca, 'FontSize', 40);
xticks([0 1]);
yticks([0 1]);
set(c, 'XTick', [0 1]);
%set(gcf, 'CLim', [0 1])
%}
%% Save figure
qsave = 1;
if qsave
    save_path = 'H:\My Documents\Multicellular automaton\figures\random_positions';
    fname_str = strrep(sprintf('Peq_trajectories_N%d_a0_%.1f_K_%d_Con_%d_noise%.1f_%s', ...
        N, a0, K, Con, noise, labels{choice}), '.', 'p');
    fname = fullfile(save_path, fname_str);
    save_figure(h, 10, 8, fname, '.pdf');
end

%-------end for loop K, Con---------
%end