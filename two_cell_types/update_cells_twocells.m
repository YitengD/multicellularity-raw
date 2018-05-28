function [cells_out, changed, h, hlist] = ...
    update_cells_twocells(cells, idx1, idx2, M, Con, K)
%%
% Update cells without noise in a positive feedback loop with infinite hill
% coefficient
% Supplement S.1.1

% Account for self-influence
% M: Matrix of cell reading, eq. S10 p.S5
%idx = dist>0;
%M = ones(size(dist)); 
%M(idx) = sinh(Rcell)./(a0*dist(idx)).*exp(Rcell-a0*dist(idx));

% Get different secretion rates and thresholds
N = numel(cells);
Con_cells = zeros(N, 1);
Con_cells(idx1) = Con(1);
Con_cells(idx2) = Con(2);
K_cells(idx1) = K(1);
K_cells(idx2) = K(2);

% Concentration in each cell
C0 = 1 + (Con_cells-1).*cells; % term in brackets of Eq. S9 p.S5

% Reading of each cell
Y = M*C0; % Eq. S9 p.S5

cells_out = Y > K_cells';
changed = ~isequal(cells_out, cells);

% hamiltonian
hlist = -(2*cells-1).*(Y-K_cells');
h = sum(hlist);

        