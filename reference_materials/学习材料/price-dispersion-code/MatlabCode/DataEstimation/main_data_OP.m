% Estimating the production parameters using OP's method and actual data

clear all
clc

dataFileName = 'data_3220';  % can choose: 'data_3117', 'data_3220', 'data_3420', 'data_3813'
load(dataFileName)

%% initialize
global data
para_0 = [ -8, .8, .3, .1, .8]; % main parameters
N = 5;  
data.W = 1*eye(N); % weight maxtrix in GMM

%% collect data
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

% Construct lags as IV
data.log_labor0_norm = zeros(length(pid_0),1);
data.log_labor_cost0_norm = zeros(length(pid_0),1);
data.log_material_cost0_norm = zeros(length(pid_0),1);
data.log_capital0_norm = zeros(length(pid_0),1);
data.log_invest0_norm = zeros(length(pid_0),1);
data.value_ratio0 = zeros(length(pid_0),1);
data.labor0_norm = zeros(length(pid_0),1);
data.labor_cost0_norm = zeros(length(pid_0),1);
data.material_cost0_norm = zeros(length(pid_0),1);
data.capital0_norm = zeros(length(pid_0),1);

for i = 2:length(data.pid_0)
    data.log_labor0_norm(i,1) = data.log_labor_norm(i-1);
    data.log_labor_cost0_norm(i,1) = data.log_labor_cost_norm(i-1);
    data.log_capital0_norm(i,1) = data.log_capital_norm(i-1);
    data.log_invest0_norm(i,1) = data.log_invest_norm(i-1);
    data.log_material_cost0_norm(i,1) = data.log_material_cost_norm(i-1);
    data.value_ratio0(i,1) = data.value_ratio(i-1);
    data.labor0_norm(i,1) = data.labor_norm(i-1);
    data.labor_cost0_norm = data.labor_cost_norm(i-1);
    data.material_cost0_norm = data.material_cost_norm(i-1);
    data.capital0_norm(i,1) = data.capital_norm(i-1);
end 

% Use cleaned data for estimation
TC = data.labor_cost + data.material_cost;
data.good = (exp(data.log_R)./TC>quantile(exp(data.log_R)./TC,quan_op)).*(exp(data.log_R)./TC<quantile(exp(data.log_R)./TC,1- quan_op)) ... 
    .*(data.ratio>quantile(data.ratio,quan_op)).*(data.ratio<quantile(data.ratio,1- quan_op)) ...
    .*(data.value_ratio>quantile(data.value_ratio,quan_op)).*(data.value_ratio<quantile(data.value_ratio,1- quan_op));

%% 1st stage OP
temp_h = [data.log_market_Q, data.log_market_p...
data.log_invest_norm, data.log_capital_norm, ...
data.log_labor_norm, data.log_material_cost_norm, ...
data.log_invest_norm.^2, data.log_capital_norm.^2, ...
data.log_labor_norm.^2, data.log_material_cost_norm.^2, ...
data.log_invest_norm.^3, data.log_capital_norm.^3, ...
data.log_labor_norm.^3, data.log_material_cost_norm.^3, ...
data.log_invest_norm.^4, data.log_capital_norm.^4, ...
data.log_labor_norm.^4, data.log_material_cost_norm.^4, ...
data.log_invest_norm.^5, data.log_capital_norm.^5, ...
data.log_labor_norm.^5, data.log_material_cost_norm.^5, ...
data.log_invest_norm.*data.log_capital_norm, ...
data.log_invest_norm.*data.log_labor_norm, ...
data.log_invest_norm.*data.log_material_cost_norm, ...
data.log_capital_norm.*data.log_labor_norm, ...
data.log_capital_norm.*data.log_material_cost_norm, ...
data.log_labor_norm.*data.log_material_cost_norm, ...
data.log_invest_norm.*data.log_capital_norm.*data.log_labor_norm, ...
data.log_invest_norm.*data.log_capital_norm.*data.log_material_cost_norm, ...
data.log_invest_norm.*data.log_labor_norm.*data.log_material_cost_norm, ...
data.log_invest_norm.*data.log_capital_norm.^2, ...
data.log_invest_norm.*data.log_labor_norm.^2, ...
data.log_invest_norm.*data.log_material_cost_norm.^2, ...
(data.log_invest_norm.^2).*data.log_capital_norm, ...
(data.log_invest_norm.^2).*data.log_labor_norm, ...
(data.log_invest_norm.^2).*data.log_material_cost_norm, ...
data.log_capital_norm.*data.log_labor_norm.^2, ...
data.log_capital_norm.*data.log_material_cost_norm.^2, ...
(data.log_capital_norm.^2).*data.log_labor_norm, ...
(data.log_capital_norm.^2).*data.log_material_cost_norm, ...
(data.log_labor_norm.^2).*data.log_material_cost_norm, ...
data.log_labor_norm.*(data.log_material_cost_norm.^2), ...
data.log_capital_norm.*data.log_labor_norm.*data.log_material_cost_norm, ...
ones(length(data.pid_0),1)];

temp_h_clean = [];
temp_R = [];

for i = 1:length(temp_h(:,1))
    if data.good(i) == 1
        temp_h_clean = [temp_h_clean; temp_h(i,:)];
        temp_R = [temp_R; data.log_R_norm(i)];
    end
end

para_est = (eye(length(temp_h_clean(1,:))))/(temp_h_clean'*temp_h_clean)*(temp_h_clean'*temp_R );
g = para_est;

data.est_phi = temp_h*g;

data.use = -999*ones(length(pid_0),1);
data.use(1) = 0;
for j = 2:length(pid_0)
  if (data.tag(j)==1 & data.good(j) ==1 & data.good(j-1) == 1)
      data.use(j) = 1;
  end
end

%% second stage OP -- GMM step 1
opt = optimoptions(@fminunc,'TolFun',1e-15,'TolX',1e-15,'MaxIter',10000,'Display','off','MaxFunEvals',10000, 'Algorithm', 'quasi-newton');
[para_est_2,fval_2,exitflag_2,output_2,grad_2,hessian_2] = fminunc('Obj_GMM_OP',para_0,opt); %'largescale','off'

sigma_2 = sqrt(diag(hessian_2.^-1));
para_est = para_est_2;

%% second stage OP -- GMM step 2
g = para_est;
ita = g(1);
gamma = (g(2)-1)/g(2);

labor_sh = data.labor_cost_avg/(data.material_cost_avg + data.labor_cost_avg + g(3)*data.labor_cost_avg);
material_sh = data.material_cost_avg/(data.material_cost_avg + data.labor_cost_avg + g(3)*data.labor_cost_avg);
capital_sh = g(3)*data.labor_cost_avg/(data.material_cost_avg + data.labor_cost_avg + g(3)*data.labor_cost_avg);
Delta =  data.log_p_avg - (1/ita).*data.log_Q_avg - (data.log_market_p - (1/ita).*data.log_market_Q);

A1 = (data.est_phi + Delta)*(ita/(1+ita)) - ...
    (1/gamma)*log(labor_sh.*(data.labor_norm.^gamma) + ... 
    material_sh.*(data.material_cost_norm.^gamma) + capital_sh*(data.capital_norm.^gamma));
A0 = zeros(length(A1),1);

for i = 2:length(data.pid_0)
    A0(i,1) = A1(i-1);
end

Innov = (A1-g(4)-g(5).*A0); 
m_time_m = 0;
for j = 2:length(pid_0)
    if data.use(j)==1
        IV_dyn = [data.log_labor0_norm(j); data.log_labor_cost0_norm(j); data.log_material_cost0_norm(j); data.log_capital_norm(j); data.log_capital0_norm(j)]*Innov(j);
        m_time_m = m_time_m + IV_dyn*IV_dyn';
    end
end

V_m = m_time_m/sum(data.use==1);
data.W = eye(N,N)/V_m;

% estimation
[para_est_3,fval_3,exitflag_3,output_3,grad_3,hessian_3] = fminunc('Obj_GMM_OP',para_0,opt); %'largescale','off'

sigma_3 = sqrt(diag(hessian_3.^-1));
para_est = para_est_3;
sigma = sigma_3;

% To show results
ita = para_est(1);
theta = para_est(2);
capital_sh = para_est(3);
h0 = para_est(4);
h1 = para_est(5);

% using normalization point to calculate
gamma = (theta-1)/theta;
material_cost_avg = exp(mean(log(material_cost)));
labor_cost_avg = exp(mean(log(labor_cost)));
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
tao = para_est(3);

% recover productivity
Delta_imputed =  data.log_p_avg - (1/ita).*data.log_Q_avg - (data.log_market_p - (1/ita).*data.log_market_Q);
A1_imputed = (data.est_phi + Delta_imputed)*(ita/(1+ita)) - ...
    (1/gamma)*log(L_norm_sh.*(data.labor_norm.^gamma) + ... 
    M_norm_sh.*(data.material_cost_norm.^gamma) + K_norm_sh*(data.capital_norm.^gamma));
omega_OP = A1_imputed; % this is the productivity estimate from OP

% Calculate inter-quartile range
IQR = quantile(A1_imputed,0.75) - quantile(A1_imputed,0.25);

% trimming
trim_omega = 0.1; % trimming parameter for productivity density estimate
A1_imputed = A1_imputed.*(A1_imputed>quantile(A1_imputed,trim_omega)).*(A1_imputed<quantile(A1_imputed,1 - 1*trim_omega));
A1_imputed_clear = [];
for m = 1:length(A1_imputed)
    if A1_imputed(m) ~= 0
        A1_imputed_clear = [A1_imputed_clear,A1_imputed(m)];
    end
end

% estimate demeaned productivity density
[f_omega,omega] = ksdensity(A1_imputed_clear-mean(A1_imputed_clear));
figure(1)
plot(omega,f_omega)
title('Kernal dentisy of productivity using OP-KG method')
xlabel('Productivity')
ylabel('Density')

%% Display production function estimate
disp(' alpha_M| alpha_L | alpha_K ');
disp([M_norm_sh, L_norm_sh, K_norm_sh]);

disp('    ita          |   sigma   |     g0    |     g1    ')
disp([ita,   theta, g(1), g(2)]);

 
