@testset "AlgAss" begin
  @showtime include("AlgAss/AbsAlgAss.jl")
  @showtime include("AlgAss/AlgAss.jl")
  @showtime include("AlgAss/AlgGrp.jl")
  @showtime include("AlgAss/AlgMat.jl")
  @showtime include("AlgAss/Elem.jl")
  @showtime include("AlgAss/Ideal.jl")
  @showtime include("AlgAss/Ramification.jl")
end
