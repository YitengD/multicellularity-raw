function [period, t_onset] = periodicity_test_short(cells_hist)
    % tests only if the last state has occured earlier    
    % returns the first found period and the time of onset of the
    % periodicity
    
    % NB works only for data with 1 repeating state. For a final state that
    % has repeated several times, it will return a higher period, which is
    % an integer multiple of the true period.
    
    t_out = numel(cells_hist) - 1;
    cells_current = cells_hist{end};
    for t=0:t_out-2
        %disp(t);
        cells = cells_hist{t+1};
        if all(all(cells==cells_current))
            period = t_out-t;
            t_onset = t;
            fprintf('First check: t_onset=%d, period upper bound: %d \n', t_onset, period);
            return
        end
    end
    period = Inf;
    t_onset = Inf;
    %disp('no period found');
end