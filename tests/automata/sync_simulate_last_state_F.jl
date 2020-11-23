
using MarkovProcesses

load_model("SIR")
load_automaton("automaton_F")
SIR.time_bound = 120.0
x1, x2, t1, t2 = 0.0, Inf, 100.0, 120.0 

A_F = create_automaton_F(SIR, x1, x2, t1, t2, "I") # <: LHA
sync_SIR = A_F * SIR

function test_last_state(A::LHA, m::SynchronizedModel)
    σ = simulate(m)
    test = (get_state_from_time(σ, (σ.S).time)[1] == (σ.S)["n"]) && ((σ.S)["d"] == 0)
    return test
end

test_all = true
nbr_sim = 10000
for i = 1:nbr_sim
    test = test_last_state(A_F, sync_SIR)
    global test_all = test_all && test
end

return test_all
