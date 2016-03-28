using BaseTestAuto
const Test = BaseTestAuto

@testset repeats=2 "This leads to 2 pass" begin
  @test true
end

@testset repeats=42 "Another but with 42 pass" begin
  @test 1 == (2-1)
end

@testset "Just using the default test set" begin
  @test true # An extra pass in the outer one to show reporting ok...

  @testset repeats=3 "3 passes and 3 fails" begin
    @test 1 == (2-1)
    @test isa(Float64, 1)
  end
end