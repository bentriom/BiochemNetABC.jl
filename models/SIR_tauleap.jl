
import StaticArrays: SVector, SMatrix, @SVector, @SMatrix
import Distributions: Poisson, rand

d=3
k=2
dict_var_SIR_tauleap = Dict("S" => 1, "I" => 2, "R" => 3)
dict_p_SIR_tauleap = Dict("ki" => 1, "kr" => 2, "tau" => 3)
l_tr_SIR_tauleap = ["U"]
p_SIR_tauleap = [0.0012, 0.05, 5.0]
x0_SIR_tauleap = [95, 5, 0]
t0_SIR_tauleap = 0.0
function SIR_tauleap_f!(xnplus1::Vector{Int}, l_t::Vector{Float64}, l_tr::Vector{Union{Nothing,String}},
                xn::Vector{Int}, tn::Float64, p::Vector{Float64})
    tau = p[3]
    a1 = p[1] * xn[1] * xn[2]
    a2 = p[2] * xn[2]
    l_a = SVector(a1, a2)
    asum = sum(l_a)
    # column-major order
    nu_1 = SVector(-1, 1, 0)
    nu_2 = SVector(0, -1, 1)
    nbr_R1 = rand(Poisson(a1*tau))
    nbr_R2 = rand(Poisson(a2*tau))
    for i = 1:3
        xnplus1[i] = xn[i]+ nbr_R1*nu_1[i] + nbr_R2*nu_2[i]
    end
    l_t[1] = tn + tau
    l_tr[1] = "U"
end
isabsorbing_SIR_tauleap(p::Vector{Float64}, xn::Vector{Int}) = (p[1]*xn[1]*xn[2] + p[2]*xn[2]) === 0.0
g_SIR_tauleap = ["I"]

SIR_tauleap = ContinuousTimeModel(d,k,dict_var_SIR_tauleap,dict_p_SIR_tauleap,l_tr_SIR_tauleap,
                                  p_SIR_tauleap,x0_SIR_tauleap,t0_SIR_tauleap,
                                  SIR_tauleap_f!,isabsorbing_SIR_tauleap; g=g_SIR_tauleap)
function create_SIR_tauleap(new_p::Vector{Float64})
    SIR_tauleap_new = deepcopy(SIR_tauleap)
    @assert length(SIR_tauleap_new.p) == length(new_p)
    set_param!(SIR_tauleap_new, new_p)
    return SIR_tauleap_new
end

export SIR_tauleap, create_SIR_tauleap
