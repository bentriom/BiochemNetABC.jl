

import StaticArrays: SVector, SMatrix, @SMatrix

State = SVector{4, Int}
Parameters = SVector{3, Real}

d=4
k=3
dict_var = Dict("E" => 1, "S" => 2, "ES" => 3, "P" => 4)
dict_p = Dict("k1" => 1, "k2" => 2, "k3" => 3)
l_tr = ["R1","R2","R3"]
p = Parameters(1.0, 1.0, 1.0)
x0 = State(100, 100, 0, 0)
t0 = 0.0

function f(xn::State, tn::Real, p::Parameters)
    a1 = p[1] * xn[1] * xn[2]
    a2 = p[2] * xn[3]
    a3 = p[3] * xn[3]
    l_a = SVector(a1, a2, a3)
    asum = sum(l_a)
    l_nu = @SMatrix [-1 1 1;
                     -1 1 0;
                     1 -1 -1;
                     0 0 1]
    u1, u2 = rand(), rand()
    tau = - log(u1) / asum
    b_inf = 0.0
    b_sup = a1
    reaction = 0
    for i = 1:3
        if b_inf < asum*u2 < b_sup
            reaction = i
            break
        end
        b_inf += l_a[i]
        b_sup += l_a[i+1]
    end
 
    nu = l_nu[:,reaction]
    xnplus1 = State(xn[1]+nu[1], xn[2]+nu[2], xn[3]+nu[3], xn[4]+nu[4])
    tnplus1 = tn + tau
    transition = "R$(reaction)"
    
    return xnplus1, tnplus1, transition
end
is_absorbing_sir(p::Parameters,xn::State) = 
    (p[1]*xn[1]*xn[2] + (p[2]+p[3])*xn[3]) == 0.0
g = SVector("P")

ER = CTMC(d,k,dict_var,dict_p,l_tr,p,x0,t0,f,is_absorbing_sir; g=g)
export ER
