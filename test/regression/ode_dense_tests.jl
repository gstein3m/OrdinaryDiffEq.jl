using OrdinaryDiffEq, Test, DiffEqBase
using ForwardDiff, Printf
using DiffEqProblemLibrary.ODEProblemLibrary: importodeproblems; importodeproblems()
import DiffEqProblemLibrary.ODEProblemLibrary: prob_ode_linear, prob_ode_2Dlinear,
                            prob_ode_bigfloatlinear, prob_ode_bigfloat2Dlinear
# use `PRINT_TESTS = true` to print the tests, including results
const PRINT_TESTS = false
print_results(x) = if PRINT_TESTS; @printf("%s \n", x) end


# points and storage arrays used in the interpolation tests
const interpolation_points = 0:1//2^(4):1
const interpolation_results_1d = fill(zero(prob_ode_linear.u0), length(interpolation_points))
const interpolation_results_2d = Vector{typeof(prob_ode_2Dlinear.u0)}(undef, length(interpolation_points))
for idx in eachindex(interpolation_results_2d)
  interpolation_results_2d[idx] = zero(prob_ode_2Dlinear.u0)
end

f_linear_inplace = (du,u,p,t) -> begin @. du = 1.01 * u end
prob_ode_linear_inplace = ODEProblem(ODEFunction(f_linear_inplace;analytic=(u0,p,t)->exp(1.01*t)*u0), [0.5], (0.,1.))
const interpolation_results_1d_inplace = Vector{typeof(prob_ode_linear_inplace.u0)}(undef, length(interpolation_points))
for idx in eachindex(interpolation_results_1d_inplace)
  interpolation_results_1d_inplace[idx] = zero(prob_ode_linear_inplace.u0)
end

const deriv_test_points = range(0, stop=1, length=5)

# perform the regression tests
# NOTE: If you want to add new tests (for new algorithms), you have to run the
#       commands below to get numerical values for `tol_ode_linear` and
#       `tol_ode_2Dlinear`.
function regression_test(alg, tol_ode_linear, tol_ode_2Dlinear; test_diff1 = false, nth_der = 1, dertol=1e-6)
  println("\n", alg)

  sol = solve(prob_ode_linear, alg, dt=1//2^(2), dense=true)
  sol(interpolation_results_1d, interpolation_points)
  sol(interpolation_points[1])
  sol2 = solve(prob_ode_linear, alg, dt=1//2^(4), dense=true, adaptive=false)
  for i in eachindex(sol2)
    print_results( @test maximum(abs.(sol2[i] - interpolation_results_1d[i])) < tol_ode_linear )
  end
  for N in 1:nth_der
    # prevent CI error
    nth_der != 1 && @show N
    if test_diff1
      sol(interpolation_results_1d, interpolation_points, Val{N})
      der = sol(interpolation_points[1], Val{N})
      @test interpolation_results_1d[1] ≈ der
      for t in deriv_test_points
        deriv = sol(t, Val{N})
        @test deriv ≈ ForwardDiff.derivative(t -> sol(t, Val{N-1}), t) rtol=dertol
      end
    end
  end

  sol = solve(prob_ode_linear_inplace, alg, dt=1//2^(2), dense=true)
  sol(interpolation_results_1d_inplace, interpolation_points, idxs=1:1)
  sol(interpolation_results_1d_inplace, interpolation_points)
  sol(interpolation_points[1], idxs=1:1)
  sol(interpolation_points[1])
  for N in 1:nth_der
    # prevent CI error
    nth_der != 1 && @show N
    if test_diff1
      sol(interpolation_results_1d_inplace, interpolation_points, Val{N}, idxs=1:1)
      sol(interpolation_results_1d_inplace, interpolation_points, Val{N})
      sol(interpolation_points[1], Val{N}, idxs=1:1)
      der = sol(interpolation_points[1], Val{N})
      @test interpolation_results_1d_inplace[1] ≈ der
      for t in deriv_test_points
        deriv = sol(t, Val{N}, idxs=1)
        @test deriv ≈ ForwardDiff.derivative(t -> sol(t, Val{N-1}; idxs=1), t) rtol=dertol
      end
    end
  end

  sol  = solve(prob_ode_2Dlinear, alg, dt=1//2^(2), dense=true)
  sol(interpolation_results_2d,  interpolation_points)
  sol(interpolation_points[1])
  sol2 = solve(prob_ode_2Dlinear, alg, dt=1//2^(4), dense=true, adaptive=false)
  for i in eachindex(sol2)
    print_results( @test maximum(maximum.(abs.(sol2[i] - interpolation_results_2d[i]))) < tol_ode_2Dlinear)
  end
end


# Some extra tests using Euler()
prob = prob_ode_linear
sol  = solve(prob, Euler(), dt=1//2^(2), dense=true)
interpd_1d = sol(0:1//2^(4):1)
sol2 = solve(prob, Euler(), dt=1//2^(4), dense=true)
sol3 = solve(prob, Euler(), dt=1//2^(5), dense=true)

prob = prob_ode_2Dlinear
sol  = solve(prob, Euler(), dt=1//2^(2), dense=true)
interpd = sol(0:1//2^(4):1)

for co in (:right, :left)
  ts = range(0, stop=last(sol.t), length=3)
  interpdright = sol(last(sol.t), continuity=co)
  interpdrights = sol(ts, continuity=co)
  @test interpdright == sol(similar(sol.u[end]), last(sol.t), continuity=co)
  tmp = [similar(sol.u[end]) for i in 1:3]
  sol(tmp, ts, continuity=co)
  @test all(map((x,y)->x==y, interpdrights, tmp))
end

interpd_idxs = sol(0:1//2^(4):1,idxs=1:2:5)

@test minimum([interpd_idxs[i] == interpd[i][1:2:5] for i in 1:length(interpd)])

interpd_single = sol(0:1//2^(4):1,idxs=1)

@test typeof(interpd_single.u) <: Vector{Float64}

@test typeof(sol(0.5,idxs=1)) <: Float64

A = rand(4,2)
sol(A,0.777)
A == sol(0.777)
sol2 = solve(prob, Euler(), dt=1//2^(4), dense=true)

@test maximum(map((x)->maximum(abs.(x)),sol2 - interpd)) < .2

sol(interpd, 0:1//2^(4):1)

@test maximum(map((x)->maximum(abs.(x)),sol2 - interpd)) < .2

sol  = solve(prob, Euler(), dt=1//2^(2), dense=false)

@test !(sol(0.6)[4,2] ≈ 0)


# Euler
regression_test(Euler(), 0.2, 0.2)

# Midpoint
regression_test(Midpoint(), 1.5e-2, 2.3e-2)

println("SSPRKs")

# SSPRK22
regression_test(SSPRK22(), 1.5e-2, 2.5e-2; test_diff1 = true, nth_der = 2, dertol = 1e-15)

# SSPRK33
regression_test(SSPRK33(), 7.5e-4, 7.5e-3; test_diff1 = true, nth_der = 2, dertol = 1e-15)

# SSPRK53
regression_test(SSPRK53(), 2.5e-4, 4.0e-4; test_diff1 = true)

# SSPRK53_2N1
regression_test(SSPRK53_2N1(), 3.0e-4, 5.5e-4; test_diff1 = true)

# SSPRK53_2N2
regression_test(SSPRK53_2N2(), 2.5e-4, 5.0e-4; test_diff1 = true)

# SSPRK63
regression_test(SSPRK63(), 1.5e-4, 3.0e-4; test_diff1 = true)

# SSPRK73
regression_test(SSPRK73(), 9.0e-5, 2.0e-4; test_diff1 = true)

# SSPRK83
regression_test(SSPRK83(), 6.5e-5, 1.5e-4; test_diff1 = true)

# SSPRK43
regression_test(SSPRK43(), 4.0e-4, 8.0e-4; test_diff1 = true, nth_der = 2, dertol = 1e-13)

# SSPRK432
regression_test(SSPRK432(), 4.0e-4, 8.0e-4; test_diff1 = true, nth_der = 2, dertol = 1e-13)

# SSPRK932
regression_test(SSPRK932(), 6.0e-5, 1.0e-4; test_diff1 = true)

# SSPRK54
regression_test(SSPRK54(), 3.5e-5, 5.5e-5)

# SSPRK104
regression_test(SSPRK104(), 1.5e-5, 3e-5)

println("Low Storage RKs")

# ORK256
regression_test(ORK256(), 3.0e-5, 5.0e-5)

# CarpenterKennedy2N54
regression_test(CarpenterKennedy2N54(), 3.0e-5, 5.0e-5)

# HSLDDRK64
regression_test(HSLDDRK64(), 3.0e-5, 3.0e-5)

# DGLDDRK73_C
regression_test(DGLDDRK73_C(), 3.0e-4, 3.0e-4)

# DGLDDRK84_C
regression_test(DGLDDRK84_C(), 3.0e-5, 5.0e-5)

# DGLDDRK84_F
regression_test(DGLDDRK84_F(), 3.0e-5, 5.0e-5)

# NDBLSRK124
regression_test(NDBLSRK124(), 3.0e-5, 3.0e-5)

# NDBLSRK134
regression_test(NDBLSRK134(), 3.0e-5, 3.0e-5)

# NDBLSRK144
regression_test(NDBLSRK144(), 3.0e-5, 3.0e-5)

# CFRLDDRK64
regression_test(CFRLDDRK64(), 3.0e-5, 3.0e-5)

# TSLDDRK74
regression_test(TSLDDRK74(), 3.0e-5, 3.0e-5)

# CKLLSRK43_2
regression_test(CKLLSRK43_2(), 2.0e-5,3.1e-5)

# CKLLSRK54_3C
regression_test(CKLLSRK54_3C(), 3.0e-5,6.0e-5)

# CKLLSRK95_4S
regression_test(CKLLSRK95_4S(), 5.0e-5,9.5e-5)

# CKLLSRK95_4C
regression_test(CKLLSRK95_4C(), 3.0e-3,5.5e-3)

# CKLLSRK95_4M
regression_test(CKLLSRK95_4M(), 5.0e-5,9.5e-5)

# CKLLSRK54_3C_3R
regression_test(CKLLSRK54_3C_3R(), 3.0e-5,6.0e-5)

# CKLLSRK54_3M_3R
regression_test(CKLLSRK54_3M_3R(), 2.0e-5,4.0e-5)

# CKLLSRK54_3N_3R
regression_test(CKLLSRK54_3N_3R(), 4.0e-5,7.0e-5)

# CKLLSRK85_4C_3R
regression_test(CKLLSRK85_4C_3R(), 8.0e-5,1.60e-4)

# CKLLSRK85_4M_3R
regression_test(CKLLSRK85_4M_3R(), 8.0e-5,1.5e-4)

# CKLLSRK85_4P_3R
regression_test(CKLLSRK85_4P_3R(), 5.5e-5,1.1e-4)

# CKLLSRK54_3N_4R
regression_test(CKLLSRK54_3N_4R(), 3.5e-5,6.0e-5)

# CKLLSRK54_3M_4R
regression_test(CKLLSRK54_3M_4R(), 2.0e-5,4.0e-5)

# CKLLSRK65_4M_4R
regression_test(CKLLSRK65_4M_4R(), 8.0e-5,1.5e-4)

# CKLLSRK85_4FM_4R
regression_test(CKLLSRK85_4FM_4R(), 1.0,1.8)

# CKLLSRK75_4M_5R
regression_test(CKLLSRK75_4M_5R(), 8.0e-5,1.6e-4)

# ParsaniKetchesonDeconinck3S32
regression_test(ParsaniKetchesonDeconinck3S32(), 1.5e-2, 2.0e-2)

# ParsaniKetchesonDeconinck3S82
regression_test(ParsaniKetchesonDeconinck3S82(), 1.5e-3, 3.0e-3)

# ParsaniKetchesonDeconinck3S53
regression_test(ParsaniKetchesonDeconinck3S53(), 2.5e-4, 4.5e-4)

# ParsaniKetchesonDeconinck3S173
regression_test(ParsaniKetchesonDeconinck3S173(), 3.5e-5, 5.5e-5)

# ParsaniKetchesonDeconinck3S94
regression_test(ParsaniKetchesonDeconinck3S94(), 1.5e-5, 3.0e-5)

# ParsaniKetchesonDeconinck3S184
regression_test(ParsaniKetchesonDeconinck3S184(), 1.5e-5, 3.0e-5)

# ParsaniKetchesonDeconinck3S105
regression_test(ParsaniKetchesonDeconinck3S105(), 1.5e-5, 3.0e-5)

# ParsaniKetchesonDeconinck3S205
regression_test(ParsaniKetchesonDeconinck3S205(), 1.5e-5, 3.0e-5)

println("RKs")

# RK4
regression_test(RK4(), 4.5e-5, 1e-4)

# DP5
regression_test(DP5(), 5e-6, 1e-5; test_diff1 = true, nth_der = 4, dertol = 1e-14)

# BS3
regression_test(BS3(), 5e-4, 8e-4)

# OwrenZen3
regression_test(OwrenZen3(), 1.5e-4, 2.5e-4; test_diff1 = true, nth_der = 3, dertol = 1e-9)

# OwrenZen4
regression_test(OwrenZen4(), 6.5e-6, 1.5e-5; test_diff1 = true, nth_der = 4, dertol = 1e-10)

# OwrenZen5
regression_test(OwrenZen5(), 1.5e-6, 2.5e-6; test_diff1 = true, nth_der = 5, dertol = 1e-8)

# Tsit5
regression_test(Tsit5(), 2e-6, 4e-6; test_diff1 = true, nth_der = 4, dertol = 1e-6)

# TanYam7
regression_test(TanYam7(), 4e-4, 6e-4)

# TsitPap8
regression_test(TsitPap8(), 1e-3, 3e-3)

# Feagin10
regression_test(Feagin10(), 6e-4, 9e-4)

# BS5
regression_test(BS5(), 4e-8, 6e-8; test_diff1 = true, nth_der = 1, dertol = 1e-12)
regression_test(BS5(lazy=false), 4e-8, 6e-8; test_diff1 = true, nth_der = 1, dertol = 1e-12)

prob = prob_ode_linear
sol  = solve(prob, BS5(), dt=1//2^(1), dense=true, adaptive=false)
interpd_1d_long = sol(0:1//2^(7):1)
sol2 = solve(prob, BS5(), dt=1//2^(7), dense=true, adaptive=false)
print_results( @test maximum(map((x)->maximum(abs.(x)),sol2 - interpd_1d_long)) < 2e-7 )

# DP8
regression_test(DP8(), 2e-7, 3e-7; test_diff1 = true, nth_der = 1, dertol = 1e-15)

prob = prob_ode_linear
sol  = solve(prob, DP8(), dt=1//2^(2), dense=true)
sol(interpd_1d_long, 0:1//2^(7):1) # inplace update
sol2 = solve(prob, DP8(), dt=1//2^(7), dense=true, adaptive=false)
print_results( @test maximum(map((x)->maximum(abs.(x)),sol2 - interpd_1d_long)) < 2e-7 )

println("Verns")

# Vern6
regression_test(Vern6(), 7e-8, 7e-8; test_diff1 = true, nth_der = 1, dertol = 1e-9)
regression_test(Vern6(lazy=false), 7e-8, 7e-8; test_diff1 = true, nth_der = 1, dertol = 1e-9)

prob = remake(prob_ode_bigfloatlinear;u0=big(0.5))

sol  = solve(prob, Vern6(), dt=1//2^(2), dense=true)
interpd_1d_big = sol(0:1//2^(7):1)
sol2 = solve(prob, Vern6(), dt=1//2^(7), dense=true, adaptive=false)
print_results( @test maximum(map((x)->maximum(abs.(x)),sol2[:] - interpd_1d_big)) < 5e-8 )

prob_ode_bigfloatveclinear = ODEProblem((u,p,t)->p*u,[big(0.5)],(0.0,1.0),big(1.01))
prob = prob_ode_bigfloatveclinear
sol  = solve(prob, Vern6(), dt=1//2^(2), dense=true)
interpd_big = sol(0:1//2^(4):1)
sol2 = solve(prob, Vern6(), dt=1//2^(4), dense=true, adaptive=false)
print_results( @test maximum(map((x)->maximum(abs.(x)),sol2 - interpd_big)) < 5e-8 )

# Vern7
regression_test(Vern7(), 3e-9, 5e-9; test_diff1 = true, nth_der = 1, dertol = 1e-10)
regression_test(Vern7(lazy=false), 3e-9, 5e-9; test_diff1 = true, nth_der = 1, dertol = 1e-10)

# Vern8
regression_test(Vern8(), 3e-8, 5e-8; test_diff1 = true, nth_der = 1, dertol = 1e-7)
regression_test(Vern8(lazy=false), 3e-8, 5e-8; test_diff1 = true, nth_der = 1, dertol = 1e-7)

# Vern9
regression_test(Vern9(), 1e-9, 2e-9; test_diff1 = true, nth_der = 4, dertol = 5e-2)
regression_test(Vern9(lazy=false), 1e-9, 2e-9; test_diff1 = true, nth_der = 4, dertol = 5e-2)

println("Rosenbrocks")

# Rosenbrock23
regression_test(Rosenbrock23(), 3e-3, 6e-3; test_diff1 = true, nth_der = 1, dertol = 1e-14)

# Rosenbrock32
regression_test(Rosenbrock32(), 6e-4, 9e-4; test_diff1 = true, nth_der = 1, dertol = 1e-14)

# Rodas4
regression_test(Rodas4(), 8.5e-6, 2e-5)

# ExplicitRK
regression_test(ExplicitRK(), 7e-5, 2e-4)

prob = prob_ode_linear
sol  = solve(prob, ExplicitRK(), dt=1//2^(2), dense=true)
# inplace interp of solution
sol(interpd_1d_long,0:1//2^(7):1)
sol2 = solve(prob, ExplicitRK(), dt=1//2^(7), dense=true, adaptive=false)
print_results( @test maximum(map((x)->maximum(abs.(x)),sol2 - interpd_1d_long)) < 6e-5 )

prob = prob_ode_2Dlinear
sol  = solve(prob, ExplicitRK(), dt=1//2^(2), dense=true)
sol(interpd, 0:1//2^(4):1)
sol2 = solve(prob, ExplicitRK(), dt=1//2^(4), dense=true, adaptive=false)
print_results( @test maximum(map((x)->maximum(abs.(x)),sol2 - interpd)) < 2e-4 )
