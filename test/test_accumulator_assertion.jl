using BaseTestAuto: AccumulatorAssertion, check, NoDecision, multicheck, isfulfilled

@testset "AccumulatorAssertion" begin

# Condition checking func used in several of the tests...
got_one_value(vs) = length(vs) == 1

@testset "checking values goes through Fail, Pass, Fail sequence when accumulating values" begin
    ta = AccumulatorAssertion(got_one_value)
    @test isa(ta, AccumulatorAssertion)

    # Fail when checking values without having added any of them
    o1 = multicheck(ta)
    @test isa(o1, Fail)

    o1 = check(ta, Returned(:(a), 1, Any[(:a, 1)]))
    @test o1 == NoDecision()
    @test length(ta.accumulator) == 1

    # Pass after having added one value
    o2 = multicheck(ta)
    @test isa(o2, Pass)

    o3 = check(ta, Returned(:(a), 2, Any[(:a, 2)]))
    @test o3 == NoDecision()
    @test length(ta.accumulator) == 2

    # Fail again since now more than 1 value accumulated
    o4 = multicheck(ta)
    @test isa(o4, Fail)

    # The default multi value assertion is never fulfilled even if it would
    # actually not make sense to continue accumulating values in this particular one...
    @test isfulfilled(ta) == false 
end

@testset "using a Set accumulator" begin
    ta = AccumulatorAssertion(got_one_value, Set{Any}())
    @test isa(ta, AccumulatorAssertion)
    o0 = multicheck(ta)
    @test isa(o0, Fail)
    o1 = check(ta, Returned(:(a), 1, Any[(:a, 1)]))
    o2 = check(ta, Returned(:(a), 1, Any[(:a, 1)]))
    @test isa(o1, NoDecision)
    @test isa(o2, NoDecision)
    @test length(ta.accumulator) == 1 # Since it is a set length is still 1
    @test isa(multicheck(ta), Pass)
    o3 = check(ta, Returned(:(b), 2, Any[(:b, 1)]))
    @test isa(multicheck(ta), Fail)
end

end