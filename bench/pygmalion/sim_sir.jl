
using BenchmarkTools
using pygmalion
using BiochemNetABC

println("Pygmalion:")

str_m = "sir_ctmc"
str_d = "abc_sir_ctmc"
pygmalion.load_model(str_m)
str_oml = "X_I,R,time"
ll_om = split(str_oml, ",")
x0 = State(95.0, 5.0, 0.0, 0.0, 0.0)
p_true = Parameters(0.0012, 0.05)
u = Control(100.0)
tml = 1:400
g_all = create_observation_function([ObserverModel(str_oml, tml)]) 
b1_pyg = @benchmark pygmalion.simulate($f, $g_all, $x0, $u, $p_true; on = nothing, full_timeline = true)
b2_pyg = @benchmark pygmalion.simulate(f, g_all, x0, u, p_true; on = nothing, full_timeline = true)

@timev pygmalion.simulate(f, g_all, x0, u, p_true; on = nothing, full_timeline = true)
@show minimum(b1_pyg), mean(b1_pyg), maximum(b1_pyg)
@show minimum(b2_pyg), mean(b2_pyg), maximum(b2_pyg)

println("BiochemNetABC:")

BiochemNetABC.load_model("SIR")
SIR.time_bound = 100.0
b1 = @benchmark BiochemNetABC.simulate($SIR)
b2 = @benchmark BiochemNetABC.simulate(SIR)

@timev BiochemNetABC.simulate(SIR)
@show minimum(b1), mean(b1), maximum(b1)
@show minimum(b2), mean(b2), maximum(b2)

