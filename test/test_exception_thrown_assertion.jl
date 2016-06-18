using BaseTestAuto: ExceptionThrownAssertion, check, Returned, Pass, Threw, Fail

@testset "ExceptionThrownAssertion" begin

@testset "pass when exception of right type was thrown" begin
    a = ExceptionThrownAssertion(ArgumentError)
    res = Threw(:(f(1)), :(f(1)), ArgumentError("a"), Any[])
    o = check(a, res)
    @test isa(o, Pass)
end

@testset "fail when exception of wrong type was thrown" begin
    a = ExceptionThrownAssertion(ArgumentError)
    res = Threw(:(f(1)), :(f(1)), KeyError("a"), Any[])
    o = check(a, res)
    @test isa(o, Fail)
end

@testset "fail when no exception was thrown" begin
    a = ExceptionThrownAssertion(ArgumentError)
    res = Returned(:(a), 1)
    o = check(a, res)
    @test isa(o, Fail)
end

end