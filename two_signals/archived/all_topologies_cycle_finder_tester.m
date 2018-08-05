clear variables 
close all
%% Testing code: update_cycle
clc
%A = [1 1 0 0; 0 0 0 1; 1 1 0 0; 0 0 1 1];
A = [0 0 0 1; 0 0 1 0; 0 1 0 0; 1 0 0 0];
%A = zeros(3);
%A(2,3)=1; A(3,2)=1;
%A = randi(2, 4)-1;
Gs = digraph(A);
g=plot(Gs);

all_cycles_func = all_topologies_cycle_finder(A);
disp('Found net cycles (function):');
for i=1:numel(all_cycles_func)
    disp(all_cycles_func{i});
end
%% Testing code: update_cycle
% Find all cycles of a given graph

n_nodes = size(A, 1);
cycles = num2cell(1:n_nodes);
all_cycles = {}; % "net" cycles
max_trials = n_nodes+1; % sequences length <= #nodes + 1

for trial=1:max_trials
    [updated_cycles] = update_sequence(A, cycles);
    [found_cycles, remaining_cycles] = trim_sequences(updated_cycles);
    for i=1:numel(found_cycles)
        all_cycles{end+1} = found_cycles{i};
    end
    cycles = remaining_cycles;
end

disp('Found cycles:');
for i=1:numel(all_cycles)
    disp(all_cycles{i});
end
%% remove equivalent cycles
all_cycles_net = {};
for i1=1:numel(all_cycles)
    same = 0;
    for i2=1:numel(all_cycles_net)
        %cycle1_trimmed = trim_sequences({all_cycles{i1}}); cycle1_trimmed = cycle1_trimmed{1};
        %cycle2_trimmed = trim_sequences({all_cycles{i2}}); cycle2_trimmed = cycle2_trimmed{1};

        % periodicity_test_seq here just trims a found cycle
        [~, cycle1_trimmed] = periodicity_test_seq(all_cycles{i1});
        [~, cycle2_trimmed] = periodicity_test_seq(all_cycles_net{i2});

        % test whether cycles are the same
        same = equivalence_test_cycles(cycle1_trimmed, cycle2_trimmed);
        if same
            % cycle has already appeared, go to next cycle
            break 
        end
    end
    if ~same
        all_cycles_net{end+1} = all_cycles{i1};
    end
end

disp('Found cycles (after removing equivalent ones):');
for i=1:numel(all_cycles_net)
    disp(all_cycles_net{i});
end
%% Testing code: periodicity_test_seq
% Works
clc
test_cycles = {};
found_cycle = [];
test_cycles{end+1} = [1 6 8 5 9 0 1 2 3];
test_cycles{end+1} = [randperm(10,5) randperm(10,5)];
test_cycles{end+1} = [randperm(10,5) randperm(10,5)];
test_cycles{end+1} = [randperm(10,5) randperm(10,5)];

for i=1:numel(test_cycles)
    [periodic, found_cycle] = periodicity_test_seq(test_cycles{i});
    disp(test_cycles{i});
    fprintf('Periodic? %d, found_cycle =  \n', periodic);
    disp(found_cycle)
end

%% Testing code: trim_sequences
% Works
clc
[found_cycles, remaining_cycles] = trim_sequences(test_cycles);

disp('Found cycles:');
for i=1:numel(found_cycles)
    disp(found_cycles{i});
end
disp('Remaining cycles:');
for i=1:numel(remaining_cycles)
    disp(remaining_cycles{i});
end


%% Testing code: shift_cycle
% Passed
clc

% shift cycle
cycle = [1 6 8 5 9 0 1 2 3];
cycle_trimmed = trim_sequences({cycle});
cycle_trimmed = cycle_trimmed{1};

shifted_cycle = cycle_trimmed;
disp('Original cycle:');
disp(cycle_trimmed);
disp('Shifted cycles:');
for i=1:numel(cycle_trimmed)
    shifted_cycle = shift_cycle(shifted_cycle);
    disp(shifted_cycle);
end

%% Testing: equivalence_test_cycles(cycle1, cycle2)
% Works
clc
cycle1 = [1 2 3 4 1];
cycle2 = [2 3 4 1 2];
same = equivalence_test_cycles(cycle1, cycle2)

cycle1 = [1 2 3 4 1];
cycle2 = [4 3 2 1 4];
same = equivalence_test_cycles(cycle1, cycle2)

cycle1 = [1 3 4 5 3 1];
cycle2 = [3 4 5 3 1 3];
same = equivalence_test_cycles(cycle1, cycle2)


%% Functions

function updated_sequences = update_sequence(A, sequences)
    % updates the sequence by 1 step; appends node children to existing
    % sequences; outputs new array of sequences 
    updated_sequences = {};
    for j1=1:numel(sequences)
        % find children
        cycle = sequences{j1};
        last_node = cycle(end);
        children_nodes = children(A, last_node);

        % add children nodes to cycles
        if numel(children_nodes)==0 
            % if node has no children, return same cycle
            updated_sequences{end+1} = cycle;
        else
            % update to new cycles
            %new_cycles = cell(numel(children_nodes), 1);
            for j2=1:numel(children_nodes)
                new_cycle = cycle;
                new_cycle(end+1) = children_nodes(j2);
                %new_cycles{i2} = new_cycle;
                updated_sequences{end+1} = new_cycle;
            end
        end

        % add new cycles to input cycles
        % updated_cycles{i1} = new_cycles;
    end
end

function [found_cycles, remaining_sequences] = trim_sequences(sequences)
    % Trims the sequences found so far, by (1) removing cycles and
    % placing them into found_cycles, (2) 
    % input sequences - (cell array)
    % output found_cycles - trimmed cycles (cell array)
    % output remaining_sequences - remaining sequences that are not
    % cycles (cell array)
    remaining_sequences = {};
    found_cycles = {};
    for j=1:numel(sequences)
        cycle = sequences{j};

        % test for periodicity
        [periodic, found_cycle] = periodicity_test_seq(cycle);
        % if not periodic, keep cycle
        if periodic
            % register trimmed cycle
            found_cycles{end+1} = found_cycle;
        else
            % keep original cyle
            remaining_sequences{end+1} = cycle;
        end
    end

    % return number array instead of cell array if there is only 1
    % element
    %if length(found_cycles)==1
    %    found_cycles = found_cycles{1};
    %end

end

function [periodic, found_cycle] = periodicity_test_seq(sequence)
    % tests whether a sequence is periodic (i.e. a cycle)
    % outputs periodic (0=non-periodic, 1=periodic),
    % outputs found_cycle (cell array of first cycle)
    if numel(unique(sequence))==sequence 
        % all unique elements => not a cycle
        periodic = 0;
        found_cycle = [];
        return
    else
        % find the first closed cycle
        for t1=1:length(sequence)
            for t2=t1+1:length(sequence)
                if (sequence(t1)==sequence(t2))
                    periodic = 1;
                    found_cycle = sequence(t1:t2);
                    return
                end

            end
        end
        periodic = 0;
        found_cycle = [];
    end
end

function same = equivalence_test_cycles(cycle1, cycle2)
    % tests whether two cycles are equivalent
    % input: cycles in form of number arrays
    % output: same (0: cycles are not the same, 1: cycles are the same)
    same = 0;
    if length(cycle1)==length(cycle2)
        shifted_cycle = cycle2;
        for j=1:numel(shifted_cycle)
            shifted_cycle = shift_cycle(shifted_cycle);
            if all(shifted_cycle==cycle1)
                same = 1;
                return
            end
        end

    end
end

function shifted_cycle = shift_cycle(cycle)
    % shifts a cycle by 1 place
    if cycle(1)~=cycle(end)
        warning('Shift_cycle: Not a cycle!');
    else
        shifted_cycle = cycle(1:end-1);
        shifted_cycle = [shifted_cycle(end) shifted_cycle];
    end
end

function out = children(A, node)
    % finds children of a node
    idx = find(A(node, :)==1);
    out = idx(idx~=node);
end
