
import StaticArrays: SVector

abstract type Model end 
abstract type ContinuousTimeModel <: Model end 
abstract type DiscreteTimeModel <: Model end 

mutable struct CTMC <: ContinuousTimeModel
    d::Int # state space dim
    k::Int # parameter space dim
    map_var_idx::Dict # maps str to full state space
    _map_obs_var_idx::Dict # maps str to observed state space
    map_param_idx::Dict # maps str in parameter space
    l_name_transitions::Vector{String}
    p::Vector{Float64}
    x0::Vector{Int}
    t0::Float64
    f!::Function
    g::Vector{String} # of dimension dobs
    _g_idx::Vector{Int} # of dimension dobs
    is_absorbing::Function
    time_bound::Float64
end

function CTMC(d::Int, k::Int, map_var_idx::Dict, map_param_idx::Dict, l_name_transitions::Vector{String}, 
              p::Vector{Float64}, x0::Vector{Int}, t0::Float64, 
              f!::Function, is_absorbing::Function; g::Vector{String} = keys(map_var_idx), time_bound::Float64 = Inf)
    dobs = length(g)
    _map_obs_var_idx = Dict()
    _g_idx = Vector{Int}(undef, dobs)
    for i = 1:dobs
        _g_idx[i] = map_var_idx[g[i]] # = ( (g[i] = i-th obs var)::String => idx in state space )
        _map_obs_var_idx[g[i]] = i
    end
    return CTMC(d, k, map_var_idx, _map_obs_var_idx, map_param_idx, l_name_transitions, p, x0, t0, f!, g, _g_idx, is_absorbing, time_bound)
end

function simulate(m::ContinuousTimeModel)
    # trajectory fields
    full_values = zeros(m.d, 0)
    times = zeros(0)
    transitions = Vector{Union{String,Nothing}}(undef,0)
    # values at time n
    n = 0
    xn = m.x0
    tn = m.t0 
    tr = [""]
    # at time n+1
    xnplus1 = zeros(Int, m.d)
    tnplus1 = zeros(Float64, 1)
    is_absorbing = (m.is_absorbing(m.p,xn))::Bool
    while !is_absorbing && (tn <= m.time_bound)
        m.f!(xnplus1, tnplus1, tr, xn, tn, m.p)
        full_values = hcat(full_values, xnplus1)
        push!(times, tnplus1[1])
        push!(transitions, tr[1])
        xn, tn = xnplus1, tnplus1[1]
        n += 1
        is_absorbing = m.is_absorbing(m.p,xn)::Bool
    end
    values = full_values[m._g_idx,:] 
    if is_bounded(m)
        if times[end] > m.time_bound
            values[:, end] = values[:,end-1]
            times[end] = m.time_bound
            transitions[end] = nothing
        end
    end
    
    return Trajectory(m, values, times, transitions)
end

function simulate(m::ContinuousTimeModel, n::Int)
    obs = ContinuousObservations(undef, n)
    for i = 1:n
        obs[i] = simulate(m)
    end
    return obs
end

is_bounded(m::Model) = m.time_bound < Inf
function check_consistency(m::Model) end
function simulate(m::Model, n::Int; bound::Float64 = Inf)::AbstractObservations end
function set_param!(m::Model, p::Vector{Float64})::Nothing end
function get_param(m::Model)::Vector{Float64} end

function load_model(name_model::String)
    include(pathof(@__MODULE__) * "/../../models/" * name_model * ".jl")
end

