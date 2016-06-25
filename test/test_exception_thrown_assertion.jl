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

@testset "setting/getting options" begin
    @testset "no options set" begin
        ta = ExceptionThrownAssertion(ArgumentError)
        @test file(ta) == "<unknown file>"
        @test line(ta) == "<unknown line>"
        @test shouldskip(ta) == false
        @test isbroken(ta) == false
    end

    @testset "file and line options set" begin
        ta = ExceptionThrownAssertion(ArgumentError)
        set_options(ta, Dict(:file => "mytestfile.jl", :line => 17))
        @test file(ta) == "mytestfile.jl"
        @test line(ta) == 17
        @test shouldskip(ta) == false
        @test isbroken(ta) == false
    end

    @testset "file and broken options set" begin
        ta = ExceptionThrownAssertion(ArgumentError)
        set_options(ta, Dict(:file => "myfile.jl", :broken => true))
        @test file(ta) == "myfile.jl"
        @test line(ta) == "<unknown line>"
        @test shouldskip(ta) == false
        @test isbroken(ta) == true
    end
end

end