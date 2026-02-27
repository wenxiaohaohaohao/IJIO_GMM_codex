% Estimating the production parameters using our method and actual data

clear all
clc

dataFileName = 'data_3220';  % can choose: 'data_3117', 'data_3220', 'data_3420', 'data_3813
load(dataFileName)

%% initialize
global data
para_0 = [-8, 1.5, .5];

% load data
data.log_R = log_R;
data.log_L = log_L;
data.labor = labor;
data.capital = capital;
data.labor_cost = labor_cost;
data.material_cost = material_cost;
data.value_ratio = value_ratio;
data.quan_ratio = quan_ratio;
data.log_value_ratio = log(value_ratio);
data.log_labor_cost = log(labor_cost);
data.log_capital = log(capital);
data.pid_0 = pid_0;
data.log_market_p = log(market_p);
data.log_market_Q = log(market_Q);
data.log_p_avg = mean(data.log_market_p);
data.log_Q_avg = mean(data.log_market_Q);
data.log_R_norm = data.log_R - mean(log_R);
data.labor_norm = exp(log_L - mean(log_L));
data.labor_cost_norm = exp(log(labor_cost) - mean(log(labor_cost)));
data.material_cost_norm = exp(log(material_cost) - mean(log(material_cost)));
data.capital_norm = exp(log_capital - mean(log_capital));
data.log_capital_norm = data.log_capital - mean(log_capital);
data.log_invest_norm = log_invest - mean(log_invest);
data.log_material_cost_norm = log(material_cost) - mean(log(material_cost));
data.log_labor_cost_norm = log(labor_cost) - mean(log(labor_cost));
data.log_labor_norm = log(labor) - mean(log(labor));
data.ratio = data.labor_norm./data.capital_norm;
data.material_cost_avg = exp(mean(log(material_cost)));
data.labor_cost_avg = exp(mean(log(labor_cost)));
data.capital_avg = exp(mean(log(capital)));

% tag the lags: tag observations for inital year of each firm
data.tag = zeros(length(data.pid_0),1);
for j = 2:length(data.pid_0)
    if data.pid_0(j)==data.pid_0(j-1)
        data.tag(j,1) = 1;
    end
end

data.log_labor0_norm = zeros(length(pid_0),1);
data.log_labor_cost0_norm = zeros(length(pid_0),1);
data.log_material_cost0_norm = zeros(length(pid_0),1);
data.log_capital0_norm = zeros(length(pid_0),1);
data.log_invest0_norm = zeros(length(pid_0),1);
data.value_ratio0 = zeros(length(pid_0),1);
data.labor0_norm = zeros(length(pid_0),1);
data.capital0_norm = zeros(length(pid_0),1);

for i = 2:length(data.pid_0)
    data.log_labor0_norm(i,1) = data.log_labor_norm(i-1);
    data.log_labor_cost0_norm(i,1) = data.log_labor_cost_norm(i-1);
    data.log_capital0_norm(i,1) = data.log_capital_norm(i-1);
    data.log_invest0_norm(i,1) = data.log_invest_norm(i-1);
    data.log_material_cost0_norm(i,1) = data.log_material_cost_norm(i-1);
    data.value_ratio0(i,1) = data.value_ratio(i-1);
    data.labor0_norm(i,1) = data.labor_norm(i-1);
    data.capital0_norm(i,1) = data.capital_norm(i-1);
end 

% Use cleaned data for estimation
TC = data.labor_cost + data.material_cost;
data.tag = (data.tag==1).*(exp(data.log_R)./TC>quantile(exp(data.log_R)./TC,quan)).*(exp(data.log_R)./TC<quantile(exp(data.log_R)./TC,1- quan)) ... 
    .*(data.ratio>quantile(data.ratio,quan)).*(data.ratio<quantile(data.ratio,1- quan)) ...
    .*(data.value_ratio>quantile(data.value_ratio,quan)).*(data.value_ratio<quantile(data.value_ratio,1- quan));

%% estimation
[para_est,resnorm,residual,exitflag,output,lambda,jacobian] = lsqnonlin('Obj_US',para_0,[], [], optimset('Tolfun',1e-15, 'TolX',1e-15,'MaxIter',500,'Display','off','MaxFunEvals',10000));
sigma = sqrt(resnorm*diag(full((jacobian'*jacobian)^-1))/length(residual));

%% Organize results to present
ita = para_est(1);
theta = para_est(2);
tau = para_est(3);

% using normalization point to calculate parameters of interest
gamma = (theta-1)/theta;
material_cost_avg = exp(mean(log(material_cost)));
labor_cost_avg = exp(mean(log(labor_cost)));
capital_sh = tau;
hours = 5000;% hours per labor
labor_avg = exp(mean(log(labor*hours)));
capital_avg = exp(mean(log(capital)));
labor_price_avg = labor_cost_avg/labor_avg;
L_norm_sh = labor_cost_avg/(labor_cost_avg + material_cost_avg + capital_sh*labor_cost_avg);
M_norm_sh = material_cost_avg/(labor_cost_avg + material_cost_avg + capital_sh*labor_cost_avg);
K_norm_sh = capital_sh*labor_cost_avg/(labor_cost_avg + material_cost_avg + capital_sh*labor_cost_avg);
material_avg = exp(mean(log(material_cost./market_p)));
mu = capital_sh*labor_cost_avg/(capital_avg^gamma*(labor_cost_avg/(labor_avg^gamma) + material_cost_avg/(material_avg^gamma)));
L_orig_sh = (1/(mu+1))*(labor_cost_avg/(labor_avg^gamma))/(labor_cost_avg/(labor_avg^gamma) + material_cost_avg/(material_avg^gamma));
M_orig_sh = (material_cost_avg/(material_avg^gamma))/(labor_cost_avg/(labor_avg^gamma))*L_orig_sh;
K_orig_sh = 1 - L_orig_sh - M_orig_sh;
pk0 = mu*data.capital_avg^(gamma-1)*(labor_cost_avg/(labor_avg^gamma) + material_cost_avg/(material_avg^gamma));
tau = para_est(3);

% recover productivity  
Delta = data.log_p_avg - (1/ita).*data.log_Q_avg - (data.log_market_p - (1/ita).*data.log_market_Q);
Q_bar = exp((ita/(1+ita))*(mean(log_R) - data.log_p_avg + data.log_Q_avg/ita));
partA = L_norm_sh.*((1+ita)./ita).*(market_p./(market_Q.^(1/ita)));
partB = (data.labor_norm.^gamma).*(Q_bar.^((1+ita)./ita))./labor_cost;
partC = (L_norm_sh*data.value_ratio.*(data.labor_norm.^gamma) + K_norm_sh*(data.capital_norm.^gamma)).^(1/(gamma*ita) + 1/gamma - 1);
omega_imputed = -(ita/(ita+1))*log(partA.*partB.*partC);
data.omega_imputed = omega_imputed;

% Calculate inter-quartile range
IQR = quantile(data.omega_imputed,0.75) - quantile(data.omega_imputed,0.25);

% Estimate productivity dynamics (AR(1) process)
opt = optimoptions(@fminunc,'TolFun',1e-15,'TolX',1e-15,'MaxIter',10000,'Display','off','MaxFunEvals',10000, 'Algorithm', 'quasi-newton');
[g,fval_g,exitflag_g,output_g,grad_g,hessian_g] = fminunc('OmegaAR',[0.2,.9],opt); 
sigma_g = sqrt(diag(hessian_g.^-1));

% trimming for density estimate
trim_omega = 0.1; % trimming parameter for productivity density estimate
A1_imputed = omega_imputed;
A1_imputed = A1_imputed.*(A1_imputed>quantile(A1_imputed,trim_omega)).*(A1_imputed<quantile(A1_imputed,1 - 1*trim_omega));
A1_imputed_clear = [];
for m = 1:length(A1_imputed)
    if A1_imputed(m) ~= 0
        A1_imputed_clear = [A1_imputed_clear,A1_imputed(m)];
    end
end

% estimate the density of demeaned productivity
[f_omega,omega] = ksdensity(A1_imputed_clear-mean(A1_imputed_clear));
figure(1)
plot(omega,f_omega)
title('Kernal dentisy of productivity using our method')
xlabel('Productivity')
ylabel('Density')

% recover material prices
M_imputed = ((L_norm_sh.*material_cost)./(M_norm_sh.*labor_cost)).^(1/gamma) .* (hours*labor) .* (material_avg/labor_avg);
PM_imputed = material_cost./M_imputed;

% estimate the density of recovered material price
trim_price = .1;
PM_imputed_trim = PM_imputed.*(PM_imputed>quantile(PM_imputed,trim_price)).*(PM_imputed<quantile(PM_imputed,1 - trim_price));

PM_imputed_clear = [];
for m = 1:length(PM_imputed_trim)
    if PM_imputed_trim(m) > 0
        PM_imputed_clear = [PM_imputed_clear,PM_imputed_trim(m)];
    end
end

[f_log_pm,log_pm] = ksdensity(log(PM_imputed_clear));
figure(2)
plot(log_pm,f_log_pm)
title('Kernal dentisy of log material prices using our method')
xlabel('log(P_M)')
ylabel('Density')

%% Display production function estimate
disp(' alpha_M|   alpha_L |   alpha_K ');
disp([ M_norm_sh, L_norm_sh, K_norm_sh]);

disp('    ita          |   sigma   |     g0    |     g1    ')
disp([ita,   theta, g(1), g(2)]);


