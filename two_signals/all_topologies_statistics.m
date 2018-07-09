%% Analyze statistics on all possible topologies (up to equivalence)
clear variables
close all
clc
%%
% Settings
single_cell = 0;
sym = 0; % include symmetric partners?
%default_save_folder = 'D:\Multicellularity\figures\two_signals\all_topologies'; % for figures
default_save_folder = 'H:\My Documents\Multicellular automaton\figures\two_signals\all_topologies'; % for figures
mastersave = 1; % switch off all save options

% Load data
load_path = 'H:\My Documents\Multicellular automaton\data\two_signals\all_topologies';
%load_path = 'D:\Multicellularity\data\two_signals\all_topologies';
labels = {'multi_cell', 'single_cell', 'multi_cell_all_incl', 'single_cell_all_incl'};
label = labels{single_cell+1 + 2*sym};
fname_str = sprintf('all_topologies_data_%s', label);

load(fullfile(load_path, fname_str));

n_data = numel(state_diagrams); % number of data points

%% Overview
% (1) number of distinct state diagrams
% (2) common state diagrams: (a) statistics, (b) plot of most common diagrams
% (3) Crude classification into (i) only ss, (ii) ss and oscillating, (iii)
% only osc
% (4) Distribution of number of steady states
% (5) Oscillation classification
% (6b) # steady states vs. # activation/repression interactions
% (6c) <osc. period> vs. # activation/repression interactions
% (6d) # oscillations vs. # steady states

%% (1) Statistics
% total number of distinct state diagrams
n_states = 4;
fprintf('Total number of diagrams: %d \n', n_data);
fprintf('Maximum number of distinct diagrams: %d \n', 2^(n_states^2));
unique_diagrams = {};
%unique_diagrams{1} = state_diagrams{1};
for i=1:n_data
    same = 0;
    for j=1:numel(unique_diagrams)
        if all(unique_diagrams{j}==state_diagrams{i})
            same = 1;
            break
        end
    end
    
    if ~same
        unique_diagrams{end+1} = state_diagrams{i};
    end
end
n_unique = numel(unique_diagrams);
fprintf('Found number of unique diagrams: %d \n', n_unique);
%% (2a) Common diagrams: statistics
% which are the most common state diagrams?
count_diagrams = zeros(1,n_unique);
for i=1:n_data
    for j=1:n_unique
        if all(unique_diagrams{j}==state_diagrams{i})
            count_diagrams(j) = count_diagrams(j) + 1;
            break
        end
    end
end
[count_diagrams_sorted, count_diagrams_I] = sort(count_diagrams, 'descend');

% Bar plot of occurence of each diagram type
h=figure(2);
%bar(1:n_unique, count_diagrams);
%bar(1:n_unique, count_diagrams_sorted);
% Alternative: scatter plot
scatter(1:n_unique, count_diagrams_sorted);

xlabel('Rank');
ylabel('Frequency');
set(gca, 'FontSize', 16);
set(h, 'Units', 'Inches', 'Position', [0 0 9 8]);
set(gca, 'XScale', 'log');
set(gca, 'YScale', 'log');
%xlim([-0.5 n_unique+0.5])
%ylim([0.1 1200])

% --> Statistics of this distribution? Zipf's Law?
% save figure
qsave = 1;
save_folder = fullfile(default_save_folder, 'rank-freq_distributions');
fname_str = sprintf('state_diagrams_ranked_%s_log_log', label);
path_out = fullfile(save_folder, fname_str);
save_figure(h, 7, 6, path_out, '.pdf', qsave && mastersave)

%% (2b) Common diagrams: draw
% get most common diagrams
num = 100; % draw 'num' number of highest scoring diagrams
%num = numel(unique_diagrams); % get all diagrams
% Plot common diagrams
close all
for i=1:num
    idx = count_diagrams_I(i);
    h = draw_state_diagram(unique_diagrams{idx}, i, count_diagrams_sorted(i) );
    
    % save figure
    qsave = 1;
    save_folder = fullfile(default_save_folder,...
        sprintf('all_diagrams_%s', label));
    fname_str = sprintf('state_diagram_%s_rank_%d', label, i);
    path_out = fullfile(save_folder, fname_str);
    save_figure(h, 7, 6, path_out, '.pdf', qsave && mastersave)
    
    close all
end

%{
% Old code
common_diagrams = [];
s = sort(count_diagrams);
for i=1:num
    idx = find(count_diagrams == s(end-i+1));
    %disp(idx);
    for j=1:numel(idx)
        % if diagram not yet included, add
        if isempty(find(common_diagrams==idx(j), 1))
            common_diagrams(end+1) = idx(j);
        end
    end
    %common_diagrams = [common_diagrams idx];
end
%common_diagrams = unique(common_diagrams);
for i=1:numel(common_diagrams)
    idx = common_diagrams(i);
    count_int_num = count_diagrams(idx);
    draw_state_diagram(unique_diagrams{idx}, i, count_int_num)
end
%}

% next: also consider symmetries?

%% (3) Crude classification
% categorization: (1) only steady states, (2) steady states & cycles, (3) only cycles
cat = zeros(3, 1); 
for i=1:n_data
    num_ss = numel(steady_states{i});
    num_cycles = numel(cycles_all{i});
    if num_ss>0 && num_cycles==0
        cat(1) = cat(1) + 1;
    elseif num_ss>0 && num_cycles>0
        cat(2) = cat(2) + 1;
    elseif num_ss==0 && num_cycles>0
        cat(3) = cat(3) + 1;
    end
end
% Check that all topologies have been found
clc
fprintf('Total # topologies found: %d \n', sum(cat));
fprintf('Total # topologies: %d \n', n_data);

h=figure(3);
bar(1:3, cat);
set(gca,'XTick', 1:3, 'XTickLabels', {'ss only','ss & cycles','cycles only'});
%xlabel('Number of steady states');
ylabel('Count');
set(gca, 'FontSize', 16);
set(h, 'Units', 'Inches', 'Position', [1 1 9 8]);
title(sprintf('Total: %d topologies', n_data));

% save figure
qsave = 1;
save_folder = default_save_folder;
fname_str = sprintf('classification_types_%s', label);
path_out = fullfile(save_folder, fname_str);
save_figure(h, 7, 6, path_out, '.pdf', qsave && mastersave)

%% (4) Number of steady states
% N.B. for a single cell, this gives the actual # of fixed points, as
% transitions are unambiguous
n_genes = 2;
n_states = n_genes^2; % # states
n_int = n_genes^n_genes; % # interactions
n_steady_states = zeros(n_states+1, 1);
for i=1:n_data
    num = numel(steady_states{i});
    n_steady_states(num+1) = n_steady_states(num+1) + 1;
end

% histogram
close all
h=figure(4);
bar(0:n_states, n_steady_states);
xlabel('Number of steady states');
ylabel('Count');
set(gca, 'FontSize', 16);
set(h, 'Units', 'Inches', 'Position', [1 1 9 8]);
title(sprintf('Total: %d topologies', n_data));

% save figure
qsave = 1;
save_folder = default_save_folder;
fname_str = sprintf('classification_num_steady_states_%s', label);
path_out = fullfile(save_folder, fname_str);
save_figure(h, 7, 6, path_out, '.pdf', qsave && mastersave)

%% (5) Oscillation classification
% --> needs reworking
% test data
%cycles_all = {{}, {[1 2 1]}, {[1 2 3 1], [2 3 2], [3 2 4 3]}};
%n_data = numel(cycles_all);

cycle_structures = cell(n_data, 1);
%n_osc =  cellfun(@numel, cycles_all); % number of oscillations 
for i=1:n_data
    cycle = cycles_all{i};
    if ~isempty(cycle)
        temp = num2str(sort(cellfun(@numel, cycle)-1));
        cycle_structures{i} = strrep(temp, '  ', ', ');
    else 
        cycle_structures{i} = '0';
    end
end
% process data into categories
categories = unique(cycle_structures);
C = categorical(cycle_structures, categories);
N = histcounts(C, categories);
[N_sorted, N_idx] = sort(N, 'descend');

% Save categories and export data
save_folder = default_save_folder;
fname_str = sprintf('classification_cycle_structures_data_%s', label);
fname = fullfile(save_folder, fname_str);
cat_sorted = categories(N_idx);
% export as .mat
save(fname, 'label', 'cat_sorted', 'N_sorted');
% export as .xslx
T = table(cat_sorted, N_sorted', 'VariableNames', {'Cycles', 'Count'});
fname = fullfile(save_folder, strcat(fname_str, '.xlsx'));
writetable(T,fname,'sheet',1,'Range','A1')
%%
for i=1:numel(idx)
    disp(steady_states{idx(i)});
    waitforbuttonpress;
end
%% histogram of cycle structures
% Example: 2, 3, 2 means there are cycles of lengths 2, 3 and 2
% respectively
h = figure(5);

%histogram(C)
bar(1:numel(unique(cycle_structures)), N_sorted);
%scatter(1:numel(unique(cycle_structures)), N_sorted);
%set(gca, 'XTickLabel', []); %1:numel(  unique(cycle_structures) ) );
xlabel('Cycle Rank');
ylabel('Frequency');
set(gca, 'FontSize', 18);
set(h, 'Units', 'Inches', 'Position', [0.2 0.2 8 8]);
title(sprintf('Total: %d topologies', n_data));
%set(gca, 'XScale', 'log');
%set(gca, 'YScale', 'log');

% save figure
qsave = 1;
save_folder = default_save_folder;
fname_str = sprintf('classification_cycle_structures_%s', label);
%save_folder = fullfile(default_save_folder, 'rank-freq_distributions');
%fname_str = sprintf('classification_cycle_structures_scatter_%s_log_linear', label);
path_out = fullfile(save_folder, fname_str);
save_figure(h, 7, 6, path_out, '.pdf', qsave && mastersave)

%% (6) heat map relations
% (a0) # steady states vs. number of interactions -> hypothesis: adding more interactions leads to
% fewer steady states on average
% (a) distribution of topologies according to # activators and # repressive
% (b) # steady states vs. activation/repression -> hypothesis: topologies with more repressors
% have more oscillatory behaviour and fewer steady states.
% (c) # oscillations vs. activation/repression -> hypothesis: topologies with more repressors
% have more oscillatory behaviour and fewer steady states.
% (d) # oscillations vs. # steady states (histogram-type heat map) ->
% hypothesis: more oscillations <-> fewer steady states 

% ------Calculations---------
count_int_num = zeros(n_states+1, n_int+1);
count_int_type = zeros(n_int+1, n_int+1); % number of data points with given interactions
ss_int_type = zeros(n_int+1, n_int+1); % # steady states 
osc_int_type = zeros(n_int+1, n_int+1); % average oscillation period

C = categorical(cycle_structures);
osc_vs_ss = zeros(n_states+1, numel(unique(C))); % #osc. vs. #steady states

for i=1:n_data
    M_int = M_int_all{i};
    n_act = sum(M_int(:)==1); % number of activating interactions
    n_rep = sum(M_int(:)==-1); % number of repressing interactions
    
    n_ss = numel(steady_states{i}); % number of steady states
    n_i = sum(abs(M_int(:))); % number of interactions
    
    count_int_num(n_ss+1, n_i+1) = count_int_num(n_ss+1, n_i+1) + 1;
    count_int_type(n_act+1, n_rep+1) = count_int_type(n_act+1, n_rep+1) + 1;
    ss_int_type(n_act+1, n_rep+1) = ss_int_type(n_act+1, n_rep+1) + n_ss;
    
    if ~isempty(cycles_all{i})
        av_osc = mean( cellfun(@numel, cycles_all{i})-1 );
        osc_int_type(n_act+1, n_rep+1) = osc_int_type(n_act+1, n_rep+1) + av_osc;
    end
    
    %idx_C = find(C(i) == categories);
    idx_C = find(C(i) == cat_sorted);
    osc_vs_ss(n_ss+1, idx_C) = osc_vs_ss(n_ss+1, idx_C) + 1;
    %scatter(n_ss, n_int, 'bo');
end

% calculate average # steady states
idx = (count_int_type~=0);
ss_data = zeros(size(count_int_type));
ss_data(idx) = ss_int_type(idx)./count_int_type(idx);
osc_int_type(idx) = osc_int_type(idx)./count_int_type(idx);
%% -----------Plots--------------
% Plot (a0)
%{
h2 = figure(2);
hold on
imagesc(0:n_states, 0:n_int, count_int_num);
set(gca,'YDir', 'normal', 'XTick', 0:n_states, 'YTick', 0:n_int);
xlabel('Number of interactions');
ylabel('Number of steady states');
set(gca, 'FontSize', 16);
xlim([-0.5 n_states+0.5]);
ylim([-0.5 n_int+0.5]);
set(h2, 'Units', 'Inches', 'Position', [1 1 9 8]);
c = colorbar;
ylabel(c, 'Number of topologies');
title(sprintf('Total: %d topologies', n_data));
%}

% Plot (a)
h = figure(6);
hold on
imagesc(0:n_int, 0:n_int, count_int_type);
[a, b] = meshgrid(0:n_int, 0:n_int);
s = string(count_int_type); s = reshape(s, 25, 1);
text(a(:), b(:), s, 'HorizontalAlignment', 'center',...
    'FontSize', 14, 'Color', 'w');
set(gca,'YDir', 'normal', 'XTick', 0:n_int, 'YTick', 0:n_int);
xlabel('Number of repressive interactions');
ylabel('Number of activating interactions');
set(gca, 'FontSize', 18);
xlim([-0.5 n_int+0.5]);
ylim([-0.5 n_int+0.5]);
set(h, 'Units', 'Inches', 'Position', [1 1 9 8]);
c = colorbar;
cm_viridis = viridis;
colormap(cm_viridis);
title(sprintf('Number of topologies (total: %d)', n_data));

% save figure
qsave = 1;
save_folder = default_save_folder;
fname_str = sprintf('classification_act_vs_rep_int_%s', label);
path_out = fullfile(save_folder, fname_str);
save_figure(h, 7, 6, path_out, '.pdf', qsave && mastersave)
%% 5b: # steady states vs. activation/repression
h = figure(7);
hold on
imagesc(0:n_int, 0:n_int, ss_data);
[a, b] = meshgrid(0:n_int, 0:n_int);
s = string(ss_data); s = reshape(s, 25, 1);
text(a(:), b(:), s, 'HorizontalAlignment', 'center',...
    'FontSize', 14, 'Color', 'w');
set(gca,'YDir', 'normal', 'XTick', 0:n_int, 'YTick', 0:n_int);
xlabel('Number of repressive interactions');
ylabel('Number of activating interactions');
set(gca, 'FontSize', 18);
xlim([-0.5 n_int+0.5]);
ylim([-0.5 n_int+0.5]);
set(h, 'Units', 'Inches', 'Position', [1 1 9 8]);
c = colorbar;
cm_viridis = viridis;
colormap(cm_viridis);
caxis([0 n_states])
title('Average number of steady states');

% save figure
qsave = 1;
save_folder = default_save_folder;
fname_str = sprintf('num_steady_states_vs_interactions_%s', label);
path_out = fullfile(save_folder, fname_str);
save_figure(h, 7, 6, path_out, '.pdf', qsave && mastersave)
%% 5c: oscillations vs. activating/repressing interactions
h = figure(8);
hold on
imagesc(0:n_int, 0:n_int, osc_int_type);
[a, b] = meshgrid(0:n_int, 0:n_int);
s = string(osc_int_type); s = reshape(s, numel(s), 1);
text(a(:), b(:), s, 'HorizontalAlignment', 'center',...
    'FontSize', 14, 'Color', 'w');
set(gca,'YDir', 'normal', 'XTick', 0:n_int, 'YTick', 0:n_int);
xlabel('Number of repressive interactions');
ylabel('Number of activating interactions');
set(gca, 'FontSize', 18);
xlim([-0.5 n_int+0.5]);
ylim([-0.5 n_int+0.5]);
set(h, 'Units', 'Inches', 'Position', [1 1 9 8]);
c = colorbar;
cm_viridis = viridis;
colormap(cm_viridis);
caxis([0 2]);
title('Average oscillation period');

% save figure
qsave = 1;
save_folder = default_save_folder;
fname_str = sprintf('num_oscillations_vs_interactions_%s', label);
path_out = fullfile(save_folder, fname_str);
save_figure(h, 7, 6, path_out, '.pdf', qsave && mastersave)

%% 6d: # oscillations vs. # steady states
% --> Fix
h = figure(9);
hold on
x = 1:numel(categories);
y = 0:n_states;
imagesc(x, y, osc_vs_ss);

[a, b] = meshgrid(x, y);
s = string(osc_vs_ss); s = reshape(s, numel(s), 1);
%text(a(:), b(:), s, 'HorizontalAlignment', 'center',...
%    'FontSize', 10, 'Color', 'w');
%set(gca,'YDir', 'normal', 'XTick', 1:numel(unique(C)), ...
%    'YTick', 0:n_states, 'XTickLabel', string(unique(C)) );
xticklabels = cell(numel(categories), 1);
ticks = [1 5:5:numel(categories)];
for i=1:numel(ticks)
    tick = ticks(i);
    xticklabels{tick} = num2str(tick);
end
set(gca,'YDir', 'normal', 'XTick', 1:numel(categories), ...
    'YTick', 0:n_states, 'XTickLabel', xticklabels );
%xlabel('Cycles');
xlabel('Cycle Rank');
ylabel('Number of steady states');
set(gca, 'FontSize', 18);
xlim([0.5 numel(unique(C))+0.5]);
ylim([-0.5 n_states+0.5]);
set(h, 'Units', 'Inches', 'Position', [1 1 9 8]);
c = colorbar;
cm_viridis = viridis;
colormap(cm_viridis);
%caxis([0 n_data]);
title(sprintf('Number of topologies (total: %d)', n_data));

% save figure
qsave = 1;
save_folder = default_save_folder;
fname_str = sprintf('num_osc_vs_num_ss_%s', label);
path_out = fullfile(save_folder, fname_str);
save_figure(h, 7, 6, path_out, '.pdf', qsave && mastersave)

%% 
% clustering of diagrams, which topologies+phases give the most similar interactions?

%% Functions
%A = state_diagrams{34};
%draw_state_diagram(A, 1, 100)

function h = draw_state_diagram(A, fig_num, count)
    % A: state diagram (graph adjacency matrix)
    % fig_num: number of figure to plot
    % count: number of times this diagram appears among all topologies
    % h: returns figure handle
    if nargin<2
        fig_num = 1;
        count = 0;
    end
    h = figure(fig_num);
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
            highlight(g, i, idx, 'LineStyle', '--', 'LineWidth', 2);
        elseif sum(A(i,:))==4
            highlight(g, i, 1:4, 'LineStyle', ':', 'LineWidth', 2);
        end
    end
    text(s-0.11,t+0.019,{'(0,0)','(1,0)','(0,1)','(1,1)'}, 'Color', 'w', 'FontSize', 32)
    
    text(0.5, 1.3, sprintf('Number of diagrams = %d', count), ...
        'FontSize', 16, 'HorizontalAlignment', 'center')
    ax = gca;
    axis([-0.4 1.4 -0.4 1.4]);
    ax.Visible = 'off';
    h.Color = [1 1 1];
    set(ax, 'Units', 'Inches', 'Position', [0 0 7 6]);
    set(h, 'Units', 'Inches', 'Position', [0.2 0.2 7 6]);
end