% To estimate the AR(1) process of productivity

function dynamics = OmegaAR(para) 

global data
g0 = para(1);
g1 = para(2);
A1 = data.omega_imputed;
for i = 2:length(data.pid_0)
    A0(i,1) = A1(i-1);
end

dynamics = sum((((A1-g0-g1.*A0).*(data.tag==1))).^2);







