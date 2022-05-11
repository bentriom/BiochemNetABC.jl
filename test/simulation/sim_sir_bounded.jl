
using MarkovProcesses 
using PyPlot

load_model("SIR")
SIR.time_bound = 100.0

σ = simulate(SIR)
plt.figure()
plt.step(times(σ), σ[:I], "ro--", marker="x", where="post", linewidth=1.0)
plt.savefig(get_module_path() * "/test/simulation/res_pics/sim_sir_bounded.svg")
plt.close()

return true

