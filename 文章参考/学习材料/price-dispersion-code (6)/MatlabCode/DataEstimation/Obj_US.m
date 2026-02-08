% Our method -- minimal distance
function Obj_US = Obj_US(g)

global data

ita = g(1);
gamma = (g(2) - 1)/g(2);
constant = (ita/(1 + ita));

temp = data.log_R - log(constant) - log( data.material_cost+ data.labor_cost.*(1 + g(3).*(data.capital_norm./data.labor_norm).^gamma));

Obj_US = [];

for i = 1:length(data.tag)
  if data.tag(i) == 1
      Obj_US = [Obj_US, temp(i)];
  end
end

    



