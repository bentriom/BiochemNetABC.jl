
import StatsBase: mean, median, std, cov, ProbabilityWeights
import Statistics: quantile
import NearestNeighbors: KDTree, knn 
import Distributions: MvNormal, Categorical
import Random: rand!

import Distributed: @sync, @async, nworkers, nprocs, workers
import DistributedArrays: DArray, dzeros, convert, localpart
using Distributed
using LinearAlgebra
using DelimitedFiles
using Logging

main_pkg_path = get_module_path()
include("$(main_pkg_path)/algorithms/_utils_abc.jl")

struct ResultAutomatonAbc
	mat_p_end::Matrix{Float64}
	mat_cov::Matrix{Float64}
    nbr_sim::Int64
    exec_time::Float64
    vec_dist::Vector{Float64}
    epsilon::Float64
    weights::Vector{Float64}
    l_ess::Vector{Float64}
end

function automaton_abc(pm::ParametricModel; nbr_particles::Int = 100, alpha::Float64 = 0.75, kernel_type = "mvnormal", 
                       NT::Float64 = nbr_particles/2, duration_time::Float64 = Inf, 
                       bound_sim::Int = typemax(Int), str_var_aut::String = "d", verbose::Int = 0) 
    @assert typeof(pm.m) <: SynchronizedModel
    @assert 0 < nbr_particles
    @assert 0.0 < alpha < 1.0
    @assert kernel_type in ["mvnormal", "knn_mvnormal"]
    dir_res = create_results_dir()
    file_cfg = open(dir_res * "cfg_abc_pmc.txt", "w")
	write(file_cfg, "ParametricModel : $(pm) \n")
	write(file_cfg, "Number of particles : $(nbr_particles) \n")
    write(file_cfg, "alpha : $(alpha) \n")
	write(file_cfg, "kernel type : $(kernel_type) \n")
    close(file_cfg)
    if nprocs() == 1
        return _automaton_abc(pm, nbr_particles, alpha, kernel_type, NT, duration_time, bound_sim, dir_res, str_var_aut)
    end
    return _distributed_automaton_abc(pm, nbr_particles, alpha, kernel_type, NT, duration_time, bound_sim, dir_res, str_var_aut)
end

# To code: 
# Pkg related: draw!, prior_density!, create_results_dir

function _automaton_abc(pm::ParametricModel, nbr_particles::Int, alpha::Float64, 
                        kernel_type::String, NT::Float64, duration_time::Float64, bound_sim::Int, 
                        dir_res::String, str_var_aut::String)
    @info "ABC PMC with $(nworkers()) processus and $(Threads.nthreads()) threads"
    begin_time = time()
    nbr_p = pm.df
    last_epsilon = 0.0
    # Init. Iteration 1
    t = 1
    epsilon = Inf
    mat_p_old = zeros(nbr_p, nbr_particles)
    vec_dist = zeros(nbr_particles)
    wl_old = zeros(nbr_particles)
    @info "Step 1 : Init"
    _init_abc_automaton!(mat_p_old, vec_dist, pm, str_var_aut)
    prior_pdf!(wl_old, pm, mat_p_old)
    normalize!(wl_old, 1)
    ess = effective_sample_size(wl_old)
    l_ess = zeros(0)
    l_ess = push!(l_ess, ess)
    flush(stdout)
    nbr_tot_sim = nbr_particles 
    current_time = time()
    old_epsilon = epsilon 
	mat_p = zeros(nbr_p, nbr_particles)
    wl_current = zeros(nbr_particles)
    l_nbr_sim = zeros(Int, nbr_particles) 
    while (epsilon > last_epsilon) && (current_time - begin_time <= duration_time) && (nbr_tot_sim <= bound_sim)
        t += 1
        begin_time_ite = time()
        @info "Step $t"
        # Set new epsilon
        epsilon = _compute_epsilon(vec_dist, alpha, old_epsilon, last_epsilon)
        @info "Current epsilon and total number of simulations" epsilon nbr_tot_sim
        @debug "5 first dist values" sort(vec_dist)[1:5]
        @debug mean(vec_dist), maximum(vec_dist), median(vec_dist), std(vec_dist)
        
        # Broadcast simulations
        mat_cov = nothing
        tree_mat_p = nothing
        if kernel_type == "mvnormal"
            mat_cov = 2 * cov(mat_p_old, ProbabilityWeights(wl_old), 2; corrected=false)
            @debug diag(mat_cov)
            if det(mat_cov) == 0.0
                @debug det(mat_cov), rank(mat_cov), effective_sample_size(wl_old)
                @error "Bad inv mat cov"
            end
        end
        if kernel_type == "knn_mvnormal"
            tree_mat_p = KDTree(mat_p_old)
        end
        Threads.@threads for i = eachindex(vec_dist)
            _update_param!(mat_p, vec_dist, l_nbr_sim, wl_current, i, pm, epsilon,
                           wl_old, mat_p_old, mat_cov, tree_mat_p, kernel_type, str_var_aut)
        end
        normalize!(wl_current, 1)
        step_nbr_sim = sum(l_nbr_sim)
        nbr_tot_sim += step_nbr_sim 
        ess = effective_sample_size(wl_current)
        l_ess = push!(l_ess, ess)
        @debug ess
        # Resampling
        if ess < NT
            @info "Resampling.."
            d_weights = Categorical(wl_current)
            ind_w = rand(d_weights, nbr_particles)
            mat_p = mat_p[:,ind_w]
            wl_current = ones(nbr_particles)
            normalize!(wl_current, 1)
            @info "End"
        end
        @info "After this step, time spent and number of simulations" steptime=(current_time-begin_time_ite) step_nbr_sim
        mat_p_old = copy(mat_p)
        wl_old = copy(wl_current)
        fill!(l_nbr_sim, 0)
        flush(stdout)
        current_time = time()
        old_epsilon = epsilon
	end

	mat_p = mat_p_old
    mat_cov = cov(mat_p, ProbabilityWeights(wl_old), 2; corrected=false)
    save_mat_p_end = false
    if save_mat_p_end
        writedlm(dir_res * "weights_end.csv", wl_old, ',')
        writedlm(dir_res * "mat_p_end.csv", mat_p_old, ',')
    end
    r = ResultAutomatonAbc(mat_p, mat_cov, nbr_tot_sim, time() - begin_time, vec_dist, epsilon, wl_old, l_ess)
    return r
end

function _distributed_automaton_abc(pm::ParametricModel, nbr_particles::Int, alpha::Float64, 
                        kernel_type::String, NT::Float64, duration_time::Float64, bound_sim::Int, 
                        dir_res::String, str_var_aut::String)
    @info "Distributed ABC PMC with $(nworkers()) processus and $(Threads.nthreads()) threads"
    begin_time = time()
    nbr_p = pm.df
    last_epsilon = 0.0
    # Init. Iteration 1
    t = 1
    epsilon = Inf
    mat_p_old = zeros(nbr_p, nbr_particles)
    vec_dist = zeros(nbr_particles)
    wl_old = zeros(nbr_particles)
    @info "Step 1 : Init"
    _init_abc_automaton!(mat_p_old, vec_dist, pm, str_var_aut)
    prior_pdf!(wl_old, pm, mat_p_old)
    normalize!(wl_old, 1)
    ess = effective_sample_size(wl_old)
    l_ess = zeros(0)
    l_ess = push!(l_ess, ess)
    flush(stdout)
    nbr_tot_sim = nbr_particles 
    current_time = time()
    old_epsilon = epsilon 
	d_mat_p = dzeros(nbr_p, nbr_particles)
    d_vec_dist = dzeros(nbr_particles)
    d_wl_current = dzeros(nbr_particles)
    mat_p = zeros(0,0)
    wl_current = zeros(0)
    while (epsilon > last_epsilon) && (current_time - begin_time <= duration_time) && (nbr_tot_sim <= bound_sim)
        t += 1
        begin_time_ite = time()
        @info "Step $t"
        # Set new epsilon
        epsilon = _compute_epsilon(vec_dist, alpha, old_epsilon, last_epsilon)
        @info "Current epsilon and total number of simulations" epsilon nbr_tot_sim
        @debug "5 first dist values" sort(vec_dist)[1:5]
        @debug mean(vec_dist), maximum(vec_dist), median(vec_dist), std(vec_dist)
        
        # Broadcast simulations
        mat_cov = nothing
        tree_mat_p = nothing
        if kernel_type == "mvnormal"
            mat_cov = 2 * cov(mat_p_old, ProbabilityWeights(wl_old), 2; corrected=false)
            @debug diag(mat_cov)
            if det(mat_cov) == 0.0
                @debug det(mat_cov), rank(mat_cov), effective_sample_size(wl_old)
                @error "Bad inv mat cov"
            end
        end
        if kernel_type == "knn_mvnormal"
            tree_mat_p = KDTree(mat_p_old)
        end
        l_nbr_sim = zeros(Int, nworkers())
        @sync for id_w in workers()
            t_id_w = id_w - workers()[1] + 1
            @async l_nbr_sim[t_id_w] = 
                remotecall_fetch(() -> _task_worker!(d_mat_p, d_vec_dist, d_wl_current, 
                                                     pm, epsilon, wl_old, mat_p_old, mat_cov, tree_mat_p, 
                                                     kernel_type, str_var_aut), id_w)
        end
        wl_current = convert(Array, d_wl_current)
        normalize!(wl_current, 1)
        mat_p = convert(Array, d_mat_p)
        step_nbr_sim = sum(l_nbr_sim)
        nbr_tot_sim += step_nbr_sim 
        ess = effective_sample_size(wl_current)
        l_ess = push!(l_ess, ess)
        @debug ess
        # Resampling
        if ess < NT
            @info "Resampling.."
            d_weights = Categorical(wl_current)
            ind_w = rand(d_weights, nbr_particles)
            mat_p = mat_p[:,ind_w]
            wl_current = ones(nbr_particles)
            normalize!(wl_current, 1)
            @info "End"
        end
        @info "After this step, time spent and number of simulations" steptime=(current_time-begin_time_ite) step_nbr_sim
        mat_p_old = mat_p
        wl_old = wl_current
        vec_dist = convert(Array, d_vec_dist)
        fill!(l_nbr_sim, 0)
        flush(stdout)
        current_time = time()
        old_epsilon = epsilon
	end

    mat_cov = cov(mat_p, ProbabilityWeights(wl_old), 2; corrected=false)
    save_mat_p_end = false
    if save_mat_p_end
        writedlm(dir_res * "weights_end.csv", wl_current, ',')
        writedlm(dir_res * "mat_p_end.csv", mat_p, ',')
    end
    r = ResultAutomatonAbc(mat_p, mat_cov, nbr_tot_sim, time() - begin_time, convert(Array, d_vec_dist), epsilon, wl_current, l_ess)
    return r
end


