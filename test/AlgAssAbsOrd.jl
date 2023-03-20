@testset "AlgAssAbsOrd" begin
  @showtime include("AlgAssAbsOrd/Order.jl")
  @showtime include("AlgAssAbsOrd/Ideal.jl")
  @showtime include("AlgAssAbsOrd/PicardGroup.jl")
  @showtime include("AlgAssAbsOrd/LocallyFreeClassGroup.jl")
  @showtime include("AlgAssAbsOrd/ICM.jl")
  @showtime include("AlgAssAbsOrd/Conjugacy.jl")
  @showtime include("AlgAssAbsOrd/Quotient.jl")
  @showtime include("AlgAssAbsOrd/FakeAbsOrdQuoRing.jl")
  @showtime include("AlgAssAbsOrd/PIP.jl")
  @showtime include("AlgAssAbsOrd/ResidueRingMultGrp.jl")
end
