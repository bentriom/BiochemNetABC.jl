
using MarkovProcesses
import LinearAlgebra: dot
import Distributions: Uniform

load_automaton("euclidean_distance_automaton")
load_model("SIR")
tml_obs = 0:0.5:200
set_time_bound!(SIR, 200.0)
y_obs = vectorize(simulate(SIR), :I, tml_obs)
sync_SIR = SIR * create_euclidean_distance_automaton(SIR, tml_obs, y_obs, :I)
σ = simulate(sync_SIR)
test = euclidean_distance(σ, :I, tml_obs, y_obs) == σ.state_lha_end[:d]
@show test, euclidean_distance(σ, :I, tml_obs, y_obs), σ.state_lha_end[:d]

return test
