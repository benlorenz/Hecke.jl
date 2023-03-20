@testset "Conjugacy" begin
  @showtime include("Conjugacy/Conjugacy.jl")
  @showtime include("Conjugacy/Husert.jl")
end
