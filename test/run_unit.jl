
using Test

@testset "Unit tests" begin
    @test include("unit/absorbing_x0.jl")
    
    @test include("unit/change_obs_var_sir.jl")
    @test include("unit/change_obs_var_sir_2.jl")
    @test include("unit/check_model_consistency.jl")
    @test include("unit/check_trajectory_consistency.jl")
    @test include("unit/create_automata.jl")
    @test include("unit/create_models.jl")
    
    @test include("unit/density_pm.jl")
    @test include("unit/dist_lp.jl")
    @test include("unit/dist_lp_var.jl")
    @test include("unit/distributed_simulation.jl")
    @test include("unit/draw_pm.jl")
    
    @test include("unit/getindex_access_trajectory.jl")
    @test include("unit/is_always_bounded_sir.jl")
    
    @test include("unit/l_dist_lp.jl")
    @test include("unit/length_obs_var.jl")
    @test include("unit/load_model.jl")
    @test include("unit/load_model_bench.jl")
    @test include("unit/load_module.jl")
    @test include("unit/long_sim_er.jl")
    
    @test include("unit/macro_network_model.jl")
    @test include("unit/model_prior.jl")
    @test include("unit/models_exps_er_1d.jl")
    @test include("unit/models_exps_er_2d.jl")
    @test include("unit/observe_all.jl")
    @test include("unit/prints.jl")
    
    @test include("unit/set_param.jl")
    @test include("unit/set_x0.jl")
    @test include("unit/side_effects_1.jl")
    @test include("unit/simulate_available_models.jl")
    @test include("unit/simulate_sir.jl")
    @test include("unit/simulate_sir_bounded.jl")
    @test include("unit/simulate_er.jl")
    @test include("unit/simulation_stop_criteria.jl")
    @test include("unit/square_wave_oscillator.jl")
    
    @test include("unit/vectorize.jl")
end

