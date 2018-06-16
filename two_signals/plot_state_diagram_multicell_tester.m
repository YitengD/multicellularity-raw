clear all;
close all;
set(0, 'defaulttextinterpreter', 'latex');
%% Input parameters
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

% calculate fN
[dist, ~] = init_dist_hex(gz, gz);
dist_vec = a0*dist(1,:);
r = dist_vec(dist_vec>0); % exclude self influence
fN = zeros(2,1);
fN(1) = sum(sinh(Rcell)*sum(exp((Rcell-r)./lambda(1)).*(lambda(1)./r)) ); % calculate signaling strength
fN(2) = sum(sinh(Rcell)*sum(exp((Rcell-r)./lambda(2)).*(lambda(2)./r)) ); % calculate signaling strength


%% Calculate transition tables
% Determine phases
R1 = (repmat(1+fN', 2, 1) - K) > 0; % Everything ON
R2 = ((repmat(Con + fN', 2, 1) - K) > 0 & (repmat(1+fN', 2, 1) - K) < 0); % ON remains ON & not all ON
R3 = ((1 + repmat(fN'.*Con, 2, 1) - K) < 0 & (repmat((1+fN').*Con, 2, 1) - K) > 0) ; % OFF remains OFF & not all OFF
R4 = (repmat((1+fN').*Con, 2, 1) - K) < 0; % Everything OFF

phase = R1 + 2*R2 + 3*R3 + 4*R4;
% 0: none (activation-deactivation)
% 1: all ON(+) / OFF(-)
% 2: ON->ON (+) / ON-> OFF (-)
% 3: OFF->OFF (+) / OFF->ON (-)
% 4: all OFF(+) / ON(-)
% 5: autonomy (+) / autonomous oscillations (-)

% Map from phase to diagram
% state | activation/repression | input molecule (1/2)
g_map = cell(2, 6, 2);
% 0=OFF, 1:ON, 2:UNKNOWN
% activation 
g_map{1,1,1} = 2*ones(2);
g_map{1,1,2} = 2*ones(2);
g_map{1,2,1} = ones(2);
g_map{1,2,2} = ones(2);
g_map{1,3,1} = [2 2; 1 1];
g_map{1,3,2} = [2 1; 2 1];
g_map{1,4,1} = [0 0; 2 2];
g_map{1,4,2} = [0 2; 0 2];
g_map{1,5,1} = zeros(2);
g_map{1,5,2} = zeros(2);
g_map{1,6,1} = [0 0; 1 1];
g_map{1,6,2} = [0 1; 0 1];
% repression 
%(note: this is precisely NOT g_map{1,:,:} in the three-val
% boolean algebra with NOT 2 = 2)
g_map{2,1,1} = 2*ones(2);
g_map{2,1,2} = 2*ones(2);
g_map{2,2,1} = zeros(2);
g_map{2,2,2} = zeros(2);
g_map{2,3,1} = [2 2; 0 0];
g_map{2,3,2} = [2 0; 2 0];
g_map{2,4,1} = [1 1; 2 2];
g_map{2,4,2} = [1 2; 1 2];
g_map{2,5,1} = ones(2);
g_map{2,5,2} = ones(2);
g_map{2,6,1} = [1 1; 0 0];
g_map{2,6,2} = [1 0; 1 0];

gij = cell(2);
X_out = cell(2, 1);
for i=1:2
    for j=1:2
        if M_int(i,j)~=0
            idx = (M_int(i,j)==1) + (M_int(i,j)==-1)*2;
            gij{i,j} = g_map{idx, phase(i,j)+1, j};
        else
            gij{i,j} = ones(2); % Fix
        end
    end
    X_out{i} = min(gij{i,1}.*gij{i,2}, 2); %easy implementation of AND for 3-val logic
    % see three_valued_logic.m
end

%% Display tables
h1 = figure(1);

% set colormap
uniq_out = unique([X_out{1} X_out{2}]);
colormap(map(uniq_out+1, :));

subplot(1, 2, 1);
imagesc([0 1], [0 1], X_out{1})
set(gca, 'YDir', 'normal');
xticks([0 1]);
yticks([0 1]);
set(gca, 'FontSize', 24);
title('$$X^{(1)}_{out}$$ ')
xlabel('$$X^{(1)}_{in}$$ ')
ylabel('$$X^{(2)}_{in}$$ ')
map = [1, 0, 0
    0, 1, 0
    0.9, 0.9, 0.1];
cb = colorbar();
caxis([min(uniq_out)-0.5 max(uniq_out)+0.5]);
set(cb, 'YTick', uniq_out);

subplot(1, 2, 2);
imagesc([0 1], [0 1], X_out{2})
set(gca, 'YDir', 'normal');
xticks([0 1]);
yticks([0 1]);
set(gca, 'FontSize', 24);
title('$$X^{(2)}_{out}$$ ')
xlabel('$$X^{(1)}_{in}$$ ')
ylabel('$$X^{(2)}_{in}$$ ')
set(h1, 'Units', 'Inches', 'Position', [1 1 11 5]);
cb = colorbar();
caxis([min(uniq_out)-0.5 max(uniq_out)+0.5]);
set(cb, 'YTick', uniq_out);


%% Calculate state diagram
A = zeros(4); % graph adjacency matrix
for i=1:2
    for j=1:2
        state_in = i + 2*(j-1); 
        X_out_this = [X_out{1}(i,j) X_out{2}(i,j)]; % tentative 
        %disp(X_out_this)
        fprintf('X_in = %d \n', state_in);
        if all(X_out_this~=2) % unambiguous out state
            state_out = X_out_this(1)+1 + 2*X_out_this(2); % (i,j) -> idx
            A(state_in, state_out) = 1;
            fprintf('X_out = %d \n', state_out);
        elseif sum(X_out_this==2)==1 % semi-definite
            if (X_out_this(1)==2)
                X_out_both = [0 X_out_this(2); 1 X_out_this(2)];
            elseif (X_out_this(2)==2)
                X_out_both = [X_out_this(1) 0; X_out_this(1) 1];
            end
            state_out = X_out_both*[1; 2]+1;
            %[X_out_both(1,1)+1 + 2*X_out_both(1,2);...
            %    X_out_both(2,1)+1 + 2*X_out_both(2,2)];
            A(state_in, state_out(1)) = 1;
            A(state_in, state_out(2)) = 1;
            fprintf('X_out = %d, %d \n', state_out(1), state_out(2));
        end
    end
end

%% Draw state diagram
h2 = figure(2);
hold on
s = [0 1 0 1];
t = [0 0 1 1];
%A = ones(4);
Gs = digraph(A);
nLabels = {};
g=plot(Gs, 'XData', s, 'YData', t, 'ArrowSize', 20, 'EdgeAlpha', 1, ...
    'LineWidth', 3, 'EdgeColor', 'k',...
    'Marker', 'o', 'MarkerSize', 100, 'NodeColor', [0.2 0.2 0.2], 'NodeLabel', nLabels);
% Make edges dashed if state has two outgoing edges
for i=1:4
    if sum(A(i,:))==2
        idx = find(A(i,:));
        highlight(g, i, idx(1), 'LineStyle', ':');
        highlight(g, i, idx(2), 'LineStyle', ':');
    end
end
text(s-0.09,t+0.015,{'(0,0)','(1,0)','(0,1)','(1,1)'}, 'Color', 'w', 'FontSize', 32)
ax = gca;
axis([-0.4 1.4 -0.4 1.4]);
ax.Visible = 'off';
h2.Color = [1 1 1];
%set(ax, 'Units', 'Inches', 'Position', [0 0 9 8]);
%set(h2, 'Units', 'Inches', 'Position', [1 1 9 8]);
set(ax, 'Units', 'Inches', 'Position', [0 0 6 6]);
set(h2, 'Units', 'Inches', 'Position', [0.1 0.1 6 6]);

%% function plot_state_diagram_multicell(M_int, Con, Coff, K)

% end