using BaseTestAuto: AccumulatorAssertion, values_include, values_are, values_vary, sometimes_equals

@testset "Top-level multi assertions" begin

@testset "values_include" begin
    a = values_include([1,2,3])
    @test isa(a, AccumulatorAssertion)

    @test isa(multicheck(a), Fail)

    check(a, Returned(:(a), 3))
    @test isa(multicheck(a), Fail)

    check(a, Returned(:(a), 1))
    @test isa(multicheck(a), Fail)

    check(a, Returned(:(a), 2))
    @test isa(multicheck(a), Pass)

    # Still true when adding values we are not looking for
    check(a, Returned(:(a), 4))
    @test isa(multicheck(a), Pass)

    # In fact it will never fail again
    for i in 1:100
        check(a, Returned(:(a), rand(1:21)))
        @test isa(multicheck(a), Pass)
    end
end

@testset "values_are" begin
    a = values_are([3,1])
    @test isa(a, AccumulatorAssertion)

    @test isa(multicheck(a), Fail)
    check(a, Returned(:(a), 1))
    @test isa(multicheck(a), Fail)
    check(a, Returned(:(a), 3))
    @test isa(multicheck(a), Pass)
    check(a, Returned(:(a), 2))
    @test isa(multicheck(a), Fail)

    # In fact it will never pass again
    for i in 1:100
        check(a, Returned(:(a), rand(1:21)))
        @test isa(multicheck(a), Fail)
    end
end

@testset "values_vary" begin
    a = values_vary()
    @test isa(a, AccumulatorAssertion)

    @test isa(multicheck(a), Fail)
    check(a, Returned(:(a), 1.0))
    @test isa(multicheck(a), Fail)

    check(a, Returned(:(a), 21.0))
    @test isa(multicheck(a), Pass)

    # In fact it will never fail again
    for i in 1:100
        check(a, Returned(:(a), rand(1:21)))
        @test isa(multicheck(a), Pass)
    end
end

@testset "sometimes_equals" begin
    a = sometimes_equals(1)
    @test isa(a, AccumulatorAssertion)
    @test isa(multicheck(a), Fail)

    # It never goes true if we add values we are not looking for
    for i in 1:100
        check(a, Returned(:(a), rand(2:42)))
        @test isa(multicheck(a), Fail)
    end

    check(a, Returned(:(a), 1))
    @test isa(multicheck(a), Pass)

    # And now it will never fail again if we add values we are not looking for...
    for i in 1:100
        check(a, Returned(:(a), rand(2:121)))
        @test isa(multicheck(a), Pass)
    end

    # ...or if we add values we are looking for
    for i in 1:100
        check(a, Returned(:(a), 1))
        @test isa(multicheck(a), Pass)
    end
end

end