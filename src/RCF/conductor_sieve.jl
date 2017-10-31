add_verbose_scope(:QuadraticExt)


##############################################################################
#
#  Sieves for primes and squarefree numbers
#
##############################################################################

function squarefree_up_to(n::Int; coprime_to::Array{fmpz,1}=fmpz[])

  list= trues(n)
  for x in coprime_to
    t=x
    while t<= n
      list[Int(t)]=false
      t+=x
    end
  end
  i=2
  b=sqrt(n)
  while i<=b
    if list[i]
      j=i^2
      if !list[j]
        i+=1
        continue
      else 
        list[j]=false
        t=2*j
        while t<= n
          list[t]=false
          t+=j
        end
      end
    end
    i+=1
  end
  return Int[i for i=1:n if list[i]]

end

function primes_up_to(n::Int)
  
  list= trues(n)
  list[1]=false
  i=2
  s=4
  while s<=n
    list[s]=false
    s+=2
  end
  i=3
  b=sqrt(n)
  while i<=b
    if list[i]
      j=3*i
      s=2*i
      while j<= n
        list[j]=false
        j+=s
      end
    end
    i+=1
  end
  return Int[i for i=1:n if list[i]]
  
end


###########################################################################
#
#  Conductors detection function 
#
###########################################################################


function tame_conductors_degree_2(O::NfOrd, bound::fmpz)
 
  K=nf(O)
  n=degree(O)
  p=2
  b1=Int(root(bound,n))
  ram_primes=collect(keys(factor(abs(O.disc)).fac))
  sort!(ram_primes)
  filter!(x -> x!=p ,ram_primes)
  cond_list=squarefree_up_to(b1, coprime_to=vcat(ram_primes,p))

  extra_list=Tuple{Int, Int}[(1,1)]
  for q in ram_primes
    tr=prime_decomposition_type(O,Int(q))
    f=tr[1][1]
    nq=Int(q)^f
    if nq> bound
      break
    end
    l=length(extra_list)
    for i=1:l
      n=extra_list[i][2]*nq
      if n> bound
        continue
      end
      push!(extra_list, (extra_list[i][1]*q, n))
    end
  end
  deleteat!(extra_list,1)

  l=length(cond_list)
  for (el,norm) in extra_list
    for i=1:l
      if cond_list[i]^n*norm>bound
        continue
      end
      push!(cond_list, cond_list[i]*el)
    end
  end

  return cond_list
  
end

function tommy_ray_class_group(O::NfOrd, n_quo::Int, m::Int)
  
  K=nf(O)
  d1=Dict{NfOrdIdl, Int}()
  lp=factor(m)
  for q in keys(lp.fac)
    lq=prime_decomposition(O,q) 
    for (P,e) in lq
      d1[P]=1
    end   
  end
  return ray_class_group(n_quo, ideal(O,1), d1, Dict{NfOrdIdl,Int}(), real_places(K))
  
end


function quadratic_normal_extensions(O::NfOrd, bound::fmpz; compute_automorphisms::Bool = false)
  
  K=nf(O)
  a=gen(K)
  Aut=Hecke.automorphisms(K)
  @assert length(Aut) == degree(K)

  #Getting a good set of generators
  Identity = Aut[1]
  for i in 1:degree(K)
    Au = Aut[i]
    if Au.prim_img == a
      Identity = Aut[i]
      break
    end
  end

  gens = Hecke.small_generating_set(Aut, *, Identity)

  #Getting conductors

  conductors=tame_conductors_degree_2(O,bound)
  @vprint :QuadraticExt "Number of conductors: $(length(conductors)) \n"
  fields=[]
  #Now, the big loop
  for (i, k) in enumerate(conductors)
    println("Conductor: $k ")
    println("Left: $(length(conductors) - i)")
    @vtime :QuadraticExt 1 r,mr=tommy_ray_class_group(O,2,k)
    println("\n Computing action ")
    @vtime :QuadraticExt 1 act=_act_on_ray_class(mr,gens)
    println("\n Searching for subgroups ")
    @vtime :QuadraticExt 1 ls=stable_subgroups(r,[2],act, op=(x, y) -> (quo(x, y, false)[2], sub(x,y,false)[2]))
    for s in ls
      C=ray_class_field(mr*inv(s[1]))
      C.norm_group=s[2]
      println("\n Computing fields")
      if Hecke._is_conductor_min_tame_normal(C, k)
        L = number_field(C)
        #if compute_automorphisms
        #  rel_auto = Hecke.rel_auto(C)
        #  autK = Aut
        #end
        @vtime :QuadraticExt 1 push!(fields, L)
      end
    end
    println("\n")
  end
  return fields

end


#
# General case
#

function squarefree_for_conductors(O::NfOrd, n::Int, deg::Int ; coprime_to::Array{fmpz,1}=fmpz[])
  
  sqf= trues(n)
  primes= trues(n)
  
  #remove primes that can be wildly ramified or
  #that are ramified in the base field
  for x in coprime_to
    t=x
    while t<= n
      sqf[Int(t)]=false
      primes[Int(t)]=false
      t+=x
    end
  end
  
  #sieving procedure
  
  if !(2 in coprime_to)
    dt=prime_decomposition_type(O,2)
    if gcd(2^dt[1][1], deg)==1
      j=2
      while j<=n
        sqf[j]=false
        primes[j]=false
        j+=2
      end
    else 
      i=2
      s=4
      while s<=n
        primes[s]=false
        s+=2
      end
      s=4
      while s<=n
        sqf[s]=false
        s+=4
      end
    end
  end
  i=3
  b=sqrt(n)
  while i<=b
    if primes[i]
      dt=prime_decomposition_type(O,i)
      if gcd(deg,i^dt[1][1]-1)==1
        primes[i]=false
        sqf[i]=false
        j=3*i
        s=2*i
        while j<= n
         primes[j]=false
         sqf[j]=false
         j+=s
        end
      else 
        j=3*i
        s=2*i
        while j<= n
          primes[j]=false
          j+=s
        end
        j=i^2
        t=2*j
        while j<= n
          sqf[j]=false
          j+=t
        end
      end
    end
    i+=2
  end
  while i<=n
    if primes[i]
      dt=prime_decomposition_type(O,i)
      if gcd(deg,i^dt[1][1]-1)==1
        sqf[i]=false
        j=3*i
        s=2*i
        while j<= n
         sqf[j]=false
         j+=s
        end
      end
    end
    i+=2
  end
  return Int[i for i=1:length(sqf) if sqf[i]]
  
end

function conductors_tame(O::NfOrd, n::Int, bound::fmpz)

  if n==2
    return tame_conductors_degree_2(O,bound)
  end
  #
  #  First, conductors coprime to the ramified primes and to the 
  #  degree of the extension we are searching for.
  # 

  K=nf(O)
  wild_ram=collect(keys(factor(fmpz(n)).fac))
  ram_primes=collect(keys(factor(O.disc).fac))
  filter!(x -> !divisible(fmpz(n),x), ram_primes)
  sort!(ram_primes)
  m=minimum(wild_ram)
  k=divexact(n,m)
  b1=Int(root(fmpz(bound),Int(degree(O)*(minimum(wild_ram)-1)*k))) 
  coprime_to=cat(1,ram_primes, wild_ram)
  list= squarefree_for_conductors(O, b1, n, coprime_to=coprime_to)

  extra_list=Tuple{Int, Int}[(1,1)]
  for q in ram_primes
    tr=prime_decomposition_type(O,Int(q))
    f=tr[1][1]
    nq=Int(q)^f
    if nq> bound
      break
    end
    l=length(extra_list)
    for i=1:l
      n=extra_list[i][2]*nq
      if n> bound
        continue
      end
      push!(extra_list, (extra_list[i][1]*q, n))
    end
  end
  deleteat!(extra_list,1)
  
  l=length(list)
  for (el,norm) in extra_list
    for i=1:l
      if list[i]^n*norm>bound
        continue
      end
      push!(list, list[i]*el)
    end
  end
  return list
end


function _are_there_subs(G::GrpAbFinGen,gtype::Array{Int,1})

  H=DiagonalGroup(gtype)
  H, _=snf(H)
  G1, _=snf(G)
  if length(G1.snf)<length(H.snf)
    return false
  end
  for i=0:length(H.snf)-1
    if !divisible(G1.snf[end-i],H.snf[end-i])
      return false
    end
  end
  return true
  
end


function abelian_extensions_Q(O::NfOrd, gtype::Array{Int,1}, bound::fmpz)
  
  inf_plc= InfPlc[]
  n=prod(gtype)
  expo=lcm(gtype)
  println("Computing the conductors ... ")
  conductors=conductors_tame(O,n,bound) 
  println("Done")
#  sort!(conductors, rev=true)
#  found_conds=Set(Int[])
  fields=[]
  #Now, the big loop
  for (i, k) in enumerate(conductors)
#    if k in found_conds
#      continue
#    end
    println("Conductor: $k ")
    println("Left: $(length(conductors) - i)")
    @vtime :QuadraticExt 1 r,mr=tommy_ray_class_group(O,expo,k)
    println("\n Searching for subgroups ")
    if !_are_there_subs(r,gtype)
      continue
    end
    @vtime :QuadraticExt 1 ls=subgroups(r, quotype=gtype, fun= (x, y) -> quo(x, y, false))
#    new_conds=divisors(k)
    for s in ls
      C=ray_class_field(mr*inv(s[2]))
      println("\n Computing fields")
#      c= Hecke._conductor_min_tame_normal(C, k)
#      if !(c in found_conds)
      if Hecke._is_conductor_min_tame_normal(C, k)
        println("\n Discriminant computation")
        if k^degree(O)>=bound
          fac=keys(factor(k).fac)
          lp=[prime_decomposition(O,q) for q in fac]
          discr=1
          for j=1:length(lp)
            d1=Dict{NfOrdIdl, Int}()
            for l=1:length(lp)
              if l!=j
                for (P,e) in lp[l]
                  d1[P]=1
                end   
              else
                for s=2:length(lp[j])
                  d1[lp[j][s][1]]=1
                end
              end
            end
            R,mR=ray_class_group(O, expo, mr, d1, inf_plc)
            dlogs=GrpAbFinGenElem[mR(s) for s in C.small_gens]
            q,mq=quo(R,dlogs)
            ap= n-order(q)
            discr*=fac[j]^(divexact(degree(O),lp[j][1][2])*ap)
          end
          if discr>bound
            continue
          end
        end
        println("\n New Field!")
        @vtime :QuadraticExt 1 push!(fields,number_field(C))
      end
    end
#    for w in new_conds
#      push!(found_conds, w)
#    end
    println("\n")
  end
  return fields
end


function divisors(n::Int)
 
 return collect(keys(factor(n).fac))
 
end

function abelian_normal_extensions(O::FlintIntegerRing, gtype::Array{Int,1}, bound::fmpz)
  Qx, x = PolynomialRing(FlintQQ, "x")
  K, a = NumberField(x - 1, "a")
  OK = maximal_order(K)
  
  fields = abelian_extensions_Q(OK, gtype, bound)
  return fields
end
  

# Bound= Norm of the discriminant of the upper extension
function abelian_normal_extensions(O::NfOrd, gtype::Array{Int,1}, bound::fmpz)
  
  K=nf(O)
  a=gen(K)
  real_plc=real_places(K)
  n=prod(gtype)
  expo=lcm(gtype)
  #
  # Getting a small set of generators
  # for the automorphisms group
  #
  Aut=Hecke.automorphisms(K)
  @assert length(Aut)==degree(O)
  
  Identity = Aut[1]
  for i in 1:degree(K)
    Au = Aut[i]
    if Au.prim_img == a
      Identity = Aut[i]
      break
    end
  end
  gens = Hecke.small_generating_set(Aut, *, Identity)
  
  #Getting conductors
  conductors=conductors_tame(O,n,bound)
#  sort!(conductors, rev=true)
  @vprint :QuadraticExt "Number of conductors: $(length(conductors)) \n"
  fields=[]
#  found_conds=Set(Int[])
  
  #Now, the big loop
  for (i, k) in enumerate(conductors)
#    if k in found_conds
#      continue
#    end
    println("Conductor: $k ")
    println("Left: $(length(conductors) - i)")
#    println("$found_conds")
    @vtime :QuadraticExt 1 r,mr=tommy_ray_class_group(O,expo,k)
    println("\n Computing action ")
    @vtime :QuadraticExt 1 act=_act_on_ray_class(mr,gens)
    println("\n Searching for subgroups ")
    @vtime :QuadraticExt 1 ls=stable_subgroups(r,gtype,act, op=(x, y) -> quo(x, y, false))
#    new_conds=divisors(k)
    for s in ls
      C=ray_class_field(mr*inv(s[2]))
      println("\n Computing fields")
#      c=Hecke._conductor_min_tame_normal(C, k)
#      if !(c in found_conds)
      if Hecke._is_conductor_min_tame_normal(C, k)
        println("\n Discriminant computation")
        if k^degree(O)>=bound
          fac=keys(factor(k).fac)
          lp=[prime_decomposition(O,q) for q in fac]
          discr=1
          for j=1:length(lp)
            d1=Dict{NfOrdIdl, Int}()
            for l=1:length(lp)
              if l!=j
                for (P,e) in lp[l]
                  d1[P]=1
                end   
              else
                for s=2:length(lp[j])
                  d1[lp[j][s][1]]=1
                end
              end
            end
            R,mR=ray_class_group(O, expo, mr, d1, inf_plc)
            dlogs=GrpAbFinGenElem[mR(s) for s in C.small_gens]
            q,mq=quo(R,dlogs)
            ap= n-order(q)
            discr*=fac[j]^(divexact(degree(O),lp[j][1][2])*ap)
          end
          if discr>bound
            continue
          end
        end
        println("\n New Field!")
        @vtime :QuadraticExt 1 push!(fields,number_field(C))
      end
    end
#    for w in new_conds
#      push!(found_conds, w)
#    end
    println("\n")
  end
  return fields

end
################################################################################
#
#   First stupid iterator
#
################################################################################

function _it_single(x, A, B)
  return Iterators.flatten(( x for x in [((push!(copy(a), x), x*b) for (a, b) in A if x*b <= B), (a for a in A)]))
end

function squarefree_numbers_from_primes(P, B)
  sort!(P, rev=true)
  @assert P[1] <= B
  A = [ (Int[1], 1) ]
  p = pop!(P)
  it = _it_single(p, A, B)
  while length(P) > 0
    p = pop!(P)
    it = _it_single(p, it, B)
  end
  return it
end
