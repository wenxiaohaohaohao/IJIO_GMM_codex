% GMM of OP method
function [Obj_GMM_OP, Innov] = Obj_GMM_OP(g) % the second output is the innovation term

global data

ita = g(1);
gamma = (g(2)-1)/g(2);

labor_sh = data.labor_cost_avg/(data.material_cost_avg + data.labor_cost_avg + g(3)*data.labor_cost_avg);
material_sh = data.material_cost_avg/(data.material_cost_avg + data.labor_cost_avg + g(3)*data.labor_cost_avg);
capital_sh = g(3)*data.labor_cost_avg/(data.material_cost_avg + data.labor_cost_avg + g(3)*data.labor_cost_avg);
Delta = data.log_p_avg - (1/ita).*data.log_Q_avg - (data.log_market_p - (1/ita).*data.log_market_Q);
A1 = (data.est_phi + Delta)*(ita/(1+ita)) - ...
    (1/gamma)*log(labor_sh.*(data.labor_norm.^gamma) + ... 
    material_sh.*(data.material_cost_norm.^gamma) + capital_sh*(data.capital_norm.^gamma));

A0 = zeros(length(A1),1);

for i = 2:length(data.pid_0)
    A0(i,1) = A1(i-1);
end

Innov = (A1-g(4)-g(5).*A0 ); 

IV_L = sum((data.log_labor0_norm.*Innov).*(data.use==1))/sum(data.use==1);
IV_LC = sum((data.log_labor_cost0_norm.*Innov).*(data.use==1))/sum(data.use==1);
IV_MC = sum((data.log_material_cost0_norm.*Innov).*(data.use==1))/sum(data.use==1);
IV_K = sum((data.log_capital_norm.*Innov).*(data.use==1))/sum(data.use==1);
IV_K0 = sum((data.log_capital0_norm.*Innov).*(data.use==1))/sum(data.use==1);

ALL = [IV_L, IV_LC, IV_MC, IV_K, IV_K0];

Obj_GMM_OP = ALL*data.W*ALL'*sum(data.tag==1);

