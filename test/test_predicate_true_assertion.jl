using BaseTestAuto: PredicateTrueAssertion, check, Returned, Pass, Threw, Fail, Error
using BaseTestAuto: TestAssertion, set_options, file, line, isbroken, shouldskip

@testset "PredicateTrueAssertion" begin

@testset "check with correct sampled value, no context" begin
    ta = PredicateTrueAssertion()
    outcome = check(ta, Returned(:(true), true, Any[]))
    @test isa(outcome, Pass)
    @test outcome.testassertion == ta

    outcome2 = check(ta, Returned(:(1 == 1), true, Any[]))
    @test isa(outcome2, Pass)
    @test outcome2.testassertion == ta
end

@testset "check with incorrect sampled value, no context" begin
    ta = PredicateTrueAssertion()
    outcome = check(ta, Returned(:(false), false, Any[]))
    @test isa(outcome, Fail)
    @test outcome.testassertion == ta

    outcome2 = check(ta, Returned(:(1 == 2), false, Any[]))
    @test isa(outcome2, Fail)
    @test outcome2.testassertion == ta
end

@testset "check with exception when sampling, no context" begin
    ta = PredicateTrueAssertion()
    ex = :(throw(ArgumentError("some error")))
    outcome = check(ta, Threw(ex, ex, ArgumentError("some error"), Any[]))
    @test isa(outcome, Error)
    @test outcome.testassertion == ta
end

@testset "show failed assertion, empty context" begin
    ta = PredicateTrueAssertion()
    outcome = check(ta, Returned(:(false), false, Any[]))
    res = show_to_string(ta, outcome)
    @test ismatch(r"Sampled expression: false", res)
    @test ismatch(r"Actual value:       false", res)
    @test ismatch(r"Expected value:     true", res)
    # No list of subexpressions since there were none in the evaluated expression...
    @test !ismatch(r"With subexpressions", res)
end

@testset "show failed assertion, non-empty context" begin
    ta = PredicateTrueAssertion()
    outcome = check(ta, Returned(:(a == 1), false, Any[(:a, 2)]))
    res = show_to_string(ta, outcome)
    @test ismatch(r"Sampled expression: a == 1", res)
    @test ismatch(r"Actual value:       false", res)
    @test ismatch(r"Expected value:     true", res)
    @test ismatch(r"With subexpressions", res)
    @test ismatch(r"a = 2", res)
end

@testset "setting/getting options" begin
    @testset "no options set" begin
        ta = PredicateTrueAssertion()
        @test file(ta) == "<unknown file>"
        @test line(ta) == "<unknown line>"
        @test shouldskip(ta) == false
        @test isbroken(ta) == false
    end

    @testset "file and line options set" begin
        ta = PredicateTrueAssertion()
        set_options(ta, Dict(:file => "myfile.jl", :line => 14))
        @test file(ta) == "myfile.jl"
        @test line(ta) == 14
        @test shouldskip(ta) == false
        @test isbroken(ta) == false
    end

    @testset "file and skip options set" begin
        ta = PredicateTrueAssertion()
        set_options(ta, Dict(:file => "myfile.jl", :skip => true))
        @test file(ta) == "myfile.jl"
        @test line(ta) == "<unknown line>"
        @test shouldskip(ta) == true
        @test isbroken(ta) == false
    end
end

end