using BaseTestAuto: PredicateTrueAssertion, Error, Threw

@testset "test assertion" begin

@testset "show failure" begin
    ta = PredicateTrueAssertion()
    # Throw exception so we can get it and its trace for testing
    ex, bt = try
        throw(ArgumentError("Missing argument 2"))
    catch _e
        (_e, catch_backtrace())
    end
    evres = Threw(:(f(a) == 1), :(f(a)), ex, Any[(:(a), 1)])
    err = Error(ta, evres, :test_error, bt)
    res = show_to_string(ta, err)
    @test ismatch(r"Test threw an exception of type ArgumentError", res)
    @test ismatch(r"In expression:\s+f\(a\) == 1", res)
    @test ismatch(r"When evaluating:\s+f\(a\)\n", res)
    @test ismatch(r"With subexpressions that evaluated to:\n\s+a = 1\n", res)

    evres2 = Threw(:(19 == f(a, b)), :(f(a, b)), ex, Any[(:(a), 1), (:(b), "a2")])
    err2 = Error(ta, evres2, :test_error, bt)
    res = show_to_string(ta, err2)
    @test ismatch(r"Test threw an exception of type ArgumentError", res)
    @test ismatch(r"In expression:\s+19 == f\(a,b\)", res)
    @test ismatch(r"When evaluating:\s+f\(a,b\)\n", res)
    @test ismatch(r"With subexpressions that evaluated to:\n\s+a = 1\n\s+b = \"a2\"", res)
end

end