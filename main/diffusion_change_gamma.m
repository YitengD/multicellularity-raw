% Compare the stationary state diffusion solution for changes in degradation.
% This evaluates if the form of the function is changed by a change in
% gamma.
clear variables
close all

% Parameters of the run
R = 0.2; % radius of cell
eta = 2; % secretion rate
D = 0.1; % diffusion constant
i = [200, 500, 800]; % index of the gamma to plot as points and analysed
gamma = linspace(0.1, 5, 1000); % parameters of gamma to test
lambda = sqrt(D./gamma); % diffusion length
cR = eta* gamma/4/pi/R./lambda./(lambda + R); % Constant to calculate secretion function

h1 = figure(1);
% plot the constant vs gamma
plot(gamma, cR, 'r', 'LineWidth', 2)
hold on
% Plot the scatter points
scatter(gamma(i), cR(i), 'bx')
hold off
% Set fonts and labels
set(gca, 'FontSize', 15)
ylabel('c_R (a.u.)', 'FontSize', 18)
xlabel('\gamma (a.u.)', 'FontSize', 18)

% Save figure as pdf
set(h1,'Units','Inches');
set(h1, 'Position', [0 0 7 6 ])
pos = get(h1,'Position');
set(h1,'PaperPositionMode','Auto','PaperUnits','Inches','PaperSize',[pos(3), pos(4)])
fig_file = fullfile(pwd, 'figures', 'cR_gamma'); % filename
print(h1, fig_file,'-dpdf','-r0')

% For each scatter, plot the form of the function in distance
r = linspace(R, 5*R, 1000);
% Plot the function shape
h2 = figure(2);
for k = 1:numel(i)
    out(k,:) = cR(i(k))*R*exp((R-r)/lambda(i(k)))./r;
end    
plot(r, out, 'LineWidth', 2)
% Set scales and labels
set(gca, 'yscale', 'log', 'FontSize', 15)
ylabel('c(r) (a.u.)', 'FontSize', 18)
xlabel('r (a.u.)', 'FontSize', 18)

% Save as pdf
set(h2,'Units','Inches');
set(h2, 'Position', [0 0 7 6 ])
pos = get(h2,'Position');
set(h2,'PaperPositionMode','Auto','PaperUnits','Inches','PaperSize',[pos(3), pos(4)])
fig_file = fullfile(pwd, 'figures', 'cR_gamma_cofr'); % filename
print(h2, fig_file,'-dpdf','-r0')
