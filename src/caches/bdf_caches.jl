mutable struct ABDF2ConstantCache{F,N,dtType,rate_prototype} <: OrdinaryDiffEqConstantCache
  uf::F
  nlsolve::N
  eulercache::ImplicitEulerConstantCache
  dtₙ₋₁::dtType
  fsalfirstprev::rate_prototype
end

function alg_cache(alg::ABDF2,u,rate_prototype,uEltypeNoUnits,uBottomEltypeNoUnits,tTypeNoUnits,
                   uprev,uprev2,f,t,dt,reltol,p,calck,::Type{Val{false}})
  @oopnlcachefields
  nlsolve = typeof(_nlsolve)(NLSolverCache(κ,tol,min_iter,max_iter,10000,new_W,z,W,1//1,1,ηold,z₊,dz,tmp,b,k))
  eulercache = ImplicitEulerConstantCache(uf,nlsolve)
  dtₙ₋₁ = one(dt)
  fsalfirstprev = rate_prototype
  nlsolve.cache.γ = 2//3
  nlsolve.cache.c = 1
  ABDF2ConstantCache(uf, nlsolve, eulercache, dtₙ₋₁, fsalfirstprev)
end

mutable struct ABDF2Cache{uType,rateType,uNoUnitsType,J,W,UF,JC,N,F,dtType} <: OrdinaryDiffEqMutableCache
  uₙ::uType
  uₙ₋₁::uType
  uₙ₋₂::uType
  du1::rateType
  fsalfirst::rateType
  fsalfirstprev::rateType
  k::rateType
  z::uType
  zₙ₋₁::uType
  dz::uType
  b::uType
  tmp::uType
  atmp::uNoUnitsType
  J::J
  W::W
  uf::UF
  jac_config::JC
  linsolve::F
  nlsolve::N
  eulercache::ImplicitEulerCache
  dtₙ₋₁::dtType
end

u_cache(c::ABDF2Cache)    = (c.z,c.dz)
du_cache(c::ABDF2Cache)   = (c.k,c.fsalfirst)

function alg_cache(alg::ABDF2,u,rate_prototype,uEltypeNoUnits,uBottomEltypeNoUnits,
                   tTypeNoUnits,uprev,uprev2,f,t,dt,reltol,p,calck,::Type{Val{true}})
  @iipnlcachefields
  nlsolve = typeof(_nlsolve)(NLSolverCache(κ,tol,min_iter,max_iter,10000,new_W,z,W,1//1,1,ηold,z₊,dz,tmp,b,k))
  atmp = similar(u,uEltypeNoUnits,axes(u))

  fsalfirstprev = similar(rate_prototype)
  eulercache = ImplicitEulerCache(u,uprev,uprev2,du1,fsalfirst,k,z,dz,b,tmp,atmp,J,W,uf,jac_config,linsolve,nlsolve)
  dtₙ₋₁ = one(dt)
  zₙ₋₁ = similar(u)
  nlsolve.cache.γ = 2//3
  nlsolve.cache.c = 1
  ABDF2Cache(u,uprev,uprev2,du1,fsalfirst,fsalfirstprev,k,z,zₙ₋₁,dz,b,tmp,atmp,J,
              W,uf,jac_config,linsolve,nlsolve,eulercache,dtₙ₋₁)
end

# QNDF1

mutable struct QNDF1ConstantCache{F,N,coefType,coefType1,dtType,uType} <: OrdinaryDiffEqConstantCache
  uf::F
  nlsolve::N
  D::coefType
  D2::coefType1
  R::coefType
  U::coefType
  uprev2::uType
  dtₙ₋₁::dtType
end

mutable struct QNDF1Cache{uType,rateType,coefType,coefType1,coefType2,uNoUnitsType,J,W,UF,JC,N,F,dtType} <: OrdinaryDiffEqMutableCache
  uprev2::uType
  du1::rateType
  fsalfirst::rateType
  k::rateType
  z::uType
  dz::uType
  b::uType
  D::coefType1
  D2::coefType2
  R::coefType
  U::coefType
  tmp::uType
  atmp::uNoUnitsType
  utilde::uType
  J::J
  W::W
  uf::UF
  jac_config::JC
  linsolve::F
  nlsolve::N
  dtₙ₋₁::dtType
end

u_cache(c::QNDF1Cache)    = ()
du_cache(c::QNDF1Cache)   = ()

function alg_cache(alg::QNDF1,u,rate_prototype,uEltypeNoUnits,uBottomEltypeNoUnits,tTypeNoUnits,uprev,uprev2,f,t,dt,reltol,p,calck,::Type{Val{false}})
  @oopnlcachefields
  uprev2 = u
  dtₙ₋₁ = t

  D = fill(zero(typeof(u)), 1, 1)
  D2 = fill(zero(typeof(u)), 1, 2)
  R = fill(zero(typeof(t)), 1, 1)
  U = fill(zero(typeof(t)), 1, 1)

  U!(1,U)
  nlsolve = typeof(_nlsolve)(NLSolverCache(κ,tol,min_iter,max_iter,10000,new_W,z,W,zero(alg.kappa),1,ηold,z₊,dz,tmp,b,k))

  QNDF1ConstantCache(uf,nlsolve,D,D2,R,U,uprev2,dtₙ₋₁)
end

function alg_cache(alg::QNDF1,u,rate_prototype,uEltypeNoUnits,uBottomEltypeNoUnits,tTypeNoUnits,uprev,uprev2,f,t,dt,reltol,p,calck,::Type{Val{true}})
  @iipnlcachefields
  D = Array{typeof(u)}(undef, 1, 1)
  D2 = Array{typeof(u)}(undef, 1, 2)
  R = fill(zero(typeof(t)), 1, 1)
  U = fill(zero(typeof(t)), 1, 1)

  D[1] = similar(u)
  D2[1] = similar(u); D2[2] = similar(u)

  U!(1,U)

  atmp = similar(u,uEltypeNoUnits,axes(u))
  utilde = similar(u,axes(u))
  uprev2 = similar(u)
  dtₙ₋₁ = one(dt)
  nlsolve = typeof(_nlsolve)(NLSolverCache(κ,tol,min_iter,max_iter,10000,new_W,z,W,zero(alg.kappa),1,ηold,z₊,dz,tmp,b,k))

  QNDF1Cache(uprev2,du1,fsalfirst,k,z,dz,b,D,D2,R,U,tmp,atmp,utilde,J,
              W,uf,jac_config,linsolve,nlsolve,dtₙ₋₁)
end

# QNDF2

mutable struct QNDF2ConstantCache{F,N,coefType,coefType1,uType,dtType} <: OrdinaryDiffEqConstantCache
  uf::F
  nlsolve::N
  D::coefType
  D2::coefType
  R::coefType1
  U::coefType1
  uprev2::uType
  uprev3::uType
  dtₙ₋₁::dtType
  dtₙ₋₂::dtType
end

mutable struct QNDF2Cache{uType,rateType,coefType,coefType1,coefType2,uNoUnitsType,J,W,UF,JC,N,F,dtType} <: OrdinaryDiffEqMutableCache
  uprev2::uType
  uprev3::uType
  du1::rateType
  fsalfirst::rateType
  k::rateType
  z::uType
  dz::uType
  b::uType
  D::coefType1
  D2::coefType2
  R::coefType
  U::coefType
  tmp::uType
  atmp::uNoUnitsType
  utilde::uType
  J::J
  W::W
  uf::UF
  jac_config::JC
  linsolve::F
  nlsolve::N
  dtₙ₋₁::dtType
  dtₙ₋₂::dtType
end

u_cache(c::QNDF2Cache)  = ()
du_cache(c::QNDF2Cache) = ()

function alg_cache(alg::QNDF2,u,rate_prototype,uEltypeNoUnits,uBottomEltypeNoUnits,tTypeNoUnits,uprev,uprev2,f,t,dt,reltol,p,calck,::Type{Val{false}})
  @oopnlcachefields
  uprev2 = u
  uprev3 = u
  dtₙ₋₁ = zero(t)
  dtₙ₋₂ = zero(t)

  D = fill(zero(typeof(u)), 1, 2)
  D2 = fill(zero(typeof(u)), 1, 3)
  R = fill(zero(typeof(t)), 2, 2)
  U = fill(zero(typeof(t)), 2, 2)

  U!(2,U)

  nlsolve = typeof(_nlsolve)(NLSolverCache(κ,tol,min_iter,max_iter,10000,new_W,z,W,zero(alg.kappa),1,ηold,z₊,dz,tmp,b,k))
  QNDF2ConstantCache(uf,nlsolve,D,D2,R,U,uprev2,uprev3,dtₙ₋₁,dtₙ₋₂)
end

function alg_cache(alg::QNDF2,u,rate_prototype,uEltypeNoUnits,uBottomEltypeNoUnits,tTypeNoUnits,uprev,uprev2,f,t,dt,reltol,p,calck,::Type{Val{true}})
  @iipnlcachefields
  D = Array{typeof(u)}(undef, 1, 2)
  D2 = Array{typeof(u)}(undef, 1, 3)
  R = fill(zero(typeof(t)), 2, 2)
  U = fill(zero(typeof(t)), 2, 2)

  D[1] = similar(u); D[2] = similar(u)
  D2[1] = similar(u);  D2[2] = similar(u); D2[3] = similar(u)

  U!(2,U)

  atmp = similar(u,uEltypeNoUnits,axes(u))
  utilde = similar(u,axes(u))
  uprev2 = similar(u)
  uprev3 = similar(u)
  dtₙ₋₁ = zero(dt)
  dtₙ₋₂ = zero(dt)

  nlsolve = typeof(_nlsolve)(NLSolverCache(κ,tol,min_iter,max_iter,10000,new_W,z,W,zero(alg.kappa),1,ηold,z₊,dz,tmp,b,k))
  QNDF2Cache(uprev2,uprev3,du1,fsalfirst,k,z,dz,b,D,D2,R,U,tmp,atmp,utilde,J,
             W,uf,jac_config,linsolve,nlsolve,dtₙ₋₁,dtₙ₋₂)
end

mutable struct QNDFConstantCache{F,N,coefType1,coefType2,coefType3,uType,uArrayType,dtType,dtsType} <: OrdinaryDiffEqConstantCache
  uf::F
  nlsolve::N
  D::coefType3
  D2::coefType2
  R::coefType1
  U::coefType1
  order::Int64
  max_order::Int64
  udiff::uArrayType
  dts::dtsType
  tmp::uType
  h::dtType
  c::Int64
end

mutable struct QNDFCache{uType,rateType,coefType1,coefType,coefType2,coefType3,dtType,dtsType,uNoUnitsType,J,W,UF,JC,N,F} <: OrdinaryDiffEqMutableCache
  du1::rateType
  fsalfirst::rateType
  k::rateType
  z::uType
  dz::uType
  b::uType
  D::coefType3
  D2::coefType2
  R::coefType1
  U::coefType1
  order::Int64
  max_order::Int64
  udiff::coefType
  dts::dtsType
  tmp::uType
  atmp::uNoUnitsType
  utilde::uType
  J::J
  W::W
  uf::UF
  jac_config::JC
  linsolve::F
  nlsolve::N
  h::dtType
  c::Int64
end

u_cache(c::QNDFCache)  = ()
du_cache(c::QNDFCache) = ()

function alg_cache(alg::QNDF,u,rate_prototype,uEltypeNoUnits,uBottomEltypeNoUnits,tTypeNoUnits,uprev,uprev2,f,t,dt,reltol,p,calck,::Type{Val{false}})
  @oopnlcachefields
  udiff = fill(zero(typeof(u)), 1, 6)
  dts = fill(zero(typeof(dt)), 1, 6)
  h = zero(dt)
  tmp = zero(u)

  D = fill(zero(typeof(u)), 1, 5)
  D2 = fill(zero(typeof(u)), 6, 6)
  R = fill(zero(typeof(t)), 5, 5)
  U = fill(zero(typeof(t)), 5, 5)

  max_order = 5

  nlsolve = typeof(_nlsolve)(NLSolverCache(κ,tol,min_iter,max_iter,10000,new_W,z,W,zero(eltype(alg.kappa)),1,ηold,z₊,dz,tmp,b,k))
  QNDFConstantCache(uf,nlsolve,D,D2,R,U,1,max_order,udiff,dts,tmp,h,0)
end

function alg_cache(alg::QNDF,u,rate_prototype,uEltypeNoUnits,uBottomEltypeNoUnits,tTypeNoUnits,uprev,uprev2,f,t,dt,reltol,p,calck,::Type{Val{true}})
  @iipnlcachefields
  udiff = Array{typeof(u)}(undef, 1, 6)
  dts = fill(zero(typeof(dt)), 1, 6)
  h = zero(dt)

  D = Array{typeof(u)}(undef, 1, 5)
  D2 = Array{typeof(u)}(undef, 6, 6)
  R = fill(zero(typeof(t)), 5, 5)
  U = fill(zero(typeof(t)), 5, 5)

  for i = 1:5
    D[i] = zero(u)
    udiff[i] = zero(u)
  end
  udiff[6] = zero(u)

  for i = 1:6
    for j = 1:6
      D2[i,j] = zero(u)
    end
  end

  max_order = 5
  atmp = similar(u,uEltypeNoUnits,axes(u))
  utilde = similar(u,axes(u))
  nlsolve = typeof(_nlsolve)(NLSolverCache(κ,tol,min_iter,max_iter,10000,new_W,z,W,zero(eltype(alg.kappa)),1,ηold,z₊,dz,tmp,b,k))

  QNDFCache(du1,fsalfirst,k,z,dz,b,D,D2,R,U,1,max_order,udiff,dts,tmp,atmp,utilde,J,
            W,uf,jac_config,linsolve,nlsolve,h,0)
end
