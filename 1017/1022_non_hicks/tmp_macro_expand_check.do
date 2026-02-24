clear
local z_A l llag klag mlag l_ind_yr
local z_B llag klag
foreach S in A B {
    local x ``z_`S''
    di "S=`S' | x=[`x']"
    tokenize `x'
    di "  token1=[`1']"
}
