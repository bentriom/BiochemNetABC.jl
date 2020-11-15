
using MarkovProcesses 
using PyPlot

load_model("SIR")
SIR.time_bound = 100.0

σ = simulate(SIR)
plt.figure()
plt.step(σ["times"], σ["I"], "ro--", marker="x", where="post", linewidth=1.0)
plt.savefig("sim_sir_bounded.png")
plt.close()
