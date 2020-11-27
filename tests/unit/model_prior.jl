
using MarkovProcesses
load_model("ER")

test_all = true

load_model("ER")
prior1 = ParametricModel(ER, ("k2", Uniform(2.0, 4.0)))
draw_model!(prior1)
test_all = test_all && 2.0 <= ER["k2"] <= 4.0 && prior1.df == 1

prior2 = ParametricModel(ER, ["k3","k2"], Product(Uniform.([2.5,6.0], [3.5,7.0])))
draw_model!(prior2)
test_all = test_all && 2.5 <= ER["k3"] <= 3.5 && 6.0 <= ER["k2"] <= 7.0 && prior2.df == 2

prior3 = ParametricModel(ER, ("k3", Uniform(10.0, 11.0)), ("k2", Uniform(13.0, 14.0)))
draw_model!(prior3)
test_all = test_all && 10.0 <= ER["k3"] <= 11.0 && 13.0 <= ER["k2"] <= 14.0 && prior3.df == 2

return test_all

