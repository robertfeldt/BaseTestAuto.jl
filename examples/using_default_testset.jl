using BaseTestAuto
const Test = BaseTestAuto

@testset repeats=2 "This leads to 2 pass" begin
  @test true
end

@testset repeats=42 "Another but with 42 pass" begin
  @test 1 == (2-1)
end

# We wrap and catch the exception thrown since we want to mimic
# the normal runtests functionality.

try

@testset "Just using the default test set" begin
  @test true # An extra pass in the outer one to show reporting ok...

  @testset repeats=3 "3 passes, 3 fails, and 3 errors" begin
    @test 1 == (2-1)
    @test isa(1, Float64) # Fail
    @test isa(Float64, 1) # Error since 2nd arg is not a type
  end

  @testset skip=true repeats=3 "Skipped so no fails from it" begin
    @test isa(Float64, 1)
  end

  @testset skip=false "Not skipped but no tests" begin
  end
end

catch err
  # Silently kill it...
end