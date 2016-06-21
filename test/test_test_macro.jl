using BaseTestAuto: isconst, iscomparison_to_const, split_comparison_in_expr_and_const
using BaseTestAuto: parse_test_macro_args

macro get_args(args...)
    args
end

@testset "@test macro" begin

@testset "isconst" begin
    @test isconst( :(1) )
    @test isconst( :(2.34) )
    @test isconst( :("str") )

    @test !isconst( :a )
    @test !isconst( :(fn(1)) )
    @test !isconst( :(fn()) )
    @test !isconst( :(fn(a,4)) )
end

@testset "iscomparison_to_const" begin
    ex = :(a==1)
    @test iscomparison_to_const(ex)

    ex2 = :(1==a)
    @test iscomparison_to_const(ex2)

    ex3 = :(b==1.5)
    @test iscomparison_to_const(ex3)

    ex4 = :("a" == b)
    @test iscomparison_to_const(ex4)

    # Not if both are variables
    ex5 = :(a == b)
    @test !iscomparison_to_const(ex5)

    # Not if one var and one function call
    ex6 = :(a == fn(1))
    @test !iscomparison_to_const(ex6)
end

@testset "split_comparison_in_expr_and_const" begin
    e, op, c = split_comparison_in_expr_and_const( :(a == 1) )
    @test  e == :a
    @test op == :(==)
    @test  c == 1

    e, op, c = split_comparison_in_expr_and_const( :(b != 2) )
    @test  e == :b
    @test op == :(!=)
    @test  c == 2

    e, op, c = split_comparison_in_expr_and_const( :(1.3 > cd) )
    @test  e == :cd
    @test op == :(<)
    @test  c == 1.3

    e, op, c = split_comparison_in_expr_and_const( :("a" < efg) )
    @test  e == :efg
    @test op == :(>)
    @test  c == "a"

    e, op, c = split_comparison_in_expr_and_const( :(1368 <= harne) )
    @test  e == :harne
    @test op == :(>=)
    @test  c == 1368

    e, op, c = split_comparison_in_expr_and_const( :(19.23 >= MyConst) )
    @test  e == :MyConst
    @test op == :(<=)
    @test  c == 19.23
end

@testset "parse_test_macro_args" begin

@testset "no assertion expr, no options" begin
    ex, orig_ex, assertionexpr, options = parse_test_macro_args(@get_args(a))
    @test ex == :(a)
    @test orig_ex == Expr(:quote, :a)
    @test assertionexpr == :(PredicateTrueAssertion())
    @test isa(options, Expr)
    @test length(options.args) == 1 # Specifying the Dict in first arg but then no values...
end

@testset "assertion type, no options" begin
    args = @get_args length(a) AccumulatorAssertion
    ex, orig_ex, assertionexpr, options = parse_test_macro_args(args)
    @test ex == :(length(a))
    @test orig_ex == Expr(:quote, ex)
    @test assertionexpr == :(AccumulatorAssertion())
    @test isa(options, Expr)
    @test length(options.args) == 1 # Specifying the Dict in first arg but then no values...
end

@testset "function call to create assertion, no options" begin
    args = @get_args length(unique(a)) values_are([1, 2])
    ex, orig_ex, assertionexpr, options = parse_test_macro_args(args)
    @test ex == :(length(unique(a)))
    @test orig_ex == Expr(:quote, ex)
    @test assertionexpr == :(values_are([1,2]))
    @test isa(options, Expr)
    @test length(options.args) == 1 # Specifying the Dict in first arg but then no values...
end

@testset "no assertion expr, file and line options" begin
    args = @get_args a file="somefile.jl" line=10
    ex, orig_ex, assertionexpr, options = parse_test_macro_args(args)
    @test ex == :(a)
    @test orig_ex == Expr(:quote, :a)
    @test assertionexpr == :(PredicateTrueAssertion())

    @test isa(options, Expr)
    @test length(options.args) == 3 # Specifying the Dict and then two args

    @test options.args[2].head == :(=>)
    @test options.args[2].args[1] == Expr(:quote, :file)
    @test options.args[2].args[2] == "somefile.jl"

    @test options.args[3].head == :(=>)
    @test options.args[3].args[1] == Expr(:quote, :line)
    @test options.args[3].args[2] == 10
end

@testset "assertion type, file option" begin
    args = @get_args length(a) AccumulatorAssertion file="a.jl"
    ex, orig_ex, assertionexpr, options = parse_test_macro_args(args)
    @test ex == :(length(a))
    @test orig_ex == Expr(:quote, ex)
    @test assertionexpr == :(AccumulatorAssertion())

    @test isa(options, Expr)
    @test length(options.args) == 2 # Specifying the Dict and then one arg

    @test options.args[2].head == :(=>)
    @test options.args[2].args[1] == Expr(:quote, :file)
    @test options.args[2].args[2] == "a.jl"
end

end

end