using BaseTestAuto: subst_expr!, split_in_subexpressions

@testset "Stepwise Expression Evaluation" begin

@testset "subst_expr! for expr not already in context" begin
    context = Any[]
    orig_ex = :( a )
    tempvar = gensym()
    ex = :(1)
    res = subst_expr!(context, orig_ex, tempvar, ex)
    @test res == tempvar
    @test length(context) == 1
end

@testset "subst_expr! for expr already in context" begin
    orig_ex = :( a )
    tempvar = gensym()
    ex = :(1)
    context = Any[(orig_ex, tempvar, ex)]
    res = subst_expr!(context, orig_ex, tempvar, ex)
    @test res == tempvar
    @test length(context) == 1 # unchanged
end

@testset "split_in_subexpressions" begin

@testset "variable compared to const" begin
    origex = :( a == 1 )
    newex, trace = split_in_subexpressions(origex)
    @test isa(newex, Expr)
    @test length(trace) == 1

    oex1, varname1, ex1 = trace[1] 
    @test oex1 == :a
    @test isa(varname1, Symbol)
    @test varname1 != :a
    @test isa(ex1, Expr)
    @test ex1 == :($(Expr(:escape, :a)))

    @test :($varname1 == 1) == newex
end

@testset "variable comparison" begin
    origex = :( a > b )
    newex, trace = split_in_subexpressions(origex)
    @test isa(newex, Expr)
    @test length(trace) == 2

    oex1, varname1, ex1 = trace[1]
    oex2, varname2, ex2 = trace[2]
    @test oex1 == :a
    @test isa(varname1, Symbol)
    @test !in(varname1, [varname2, :a, :b])
    @test isa(ex1, Expr)
    @test ex1 == :($(Expr(:escape, :a)))

    @test oex2 == :b
    @test isa(varname2, Symbol)
    @test !in(varname2, [varname1, :a, :b])
    @test isa(ex2, Expr)
    @test ex2 == :($(Expr(:escape, :b)))

    @test :($varname1 > $varname2) == newex    
end

@testset "variable in a function call" begin
    origex = :( f(a) > 1 )
    newex, trace = split_in_subexpressions(origex)
    @test isa(newex, Expr)
    @test length(trace) == 2

    oex1, varname1, ex1 = trace[1]
    oex2, varname2, ex2 = trace[2]

    @test oex1 == :a
    @test isa(varname1, Symbol)
    @test !in(varname1, [varname2, :a])
    @test isa(ex1, Expr)
    @test ex1 == :($(Expr(:escape, :a)))

    @test oex2 == :(f(a))
    @test isa(varname2, Symbol)
    @test !in(varname2, [varname1, :a])
    @test isa(ex2, Expr)
    @test ex2 == :(f($varname1))

    @test :($varname2 > 1) == newex    
end

@testset "nested function calls" begin
    origex = :( 2 < f(g(cd, 3), "a") )
    newex, trace = split_in_subexpressions(origex)
    @test isa(newex, Expr)
    @test length(trace) == 3

    oex1, varname1, ex1 = trace[1]
    oex2, varname2, ex2 = trace[2]
    oex3, varname3, ex3 = trace[3]

    @test oex1 == :cd
    @test isa(varname1, Symbol)
    @test !in(varname1, [varname3, varname2, :cd])
    @test isa(ex1, Expr)
    @test ex1 == :($(Expr(:escape, :cd)))

    @test oex2 == :(g(cd, 3))
    @test isa(varname2, Symbol)
    @test !in(varname2, [varname3, varname1, :cd])
    @test isa(ex2, Expr)
    @test ex2 == :(g($varname1, 3))

    @test oex3 == :(f(g(cd, 3), "a"))
    @test isa(varname3, Symbol)
    @test !in(varname3, [varname2, varname1, :cd])
    @test isa(ex3, Expr)
    @test ex3 == :(f($varname2, "a"))

    @test :(2 < $varname3) == newex    
end

@testset "sub expressions reused" begin
    origex = :( a == (a + b) )
    newex, trace = split_in_subexpressions(origex)
    @test isa(newex, Expr)
    @test length(trace) == 3

    oex1, varname1, ex1 = trace[1]
    oex2, varname2, ex2 = trace[2]
    oex3, varname3, ex3 = trace[3]

    @test oex1 == :a
    @test isa(varname1, Symbol)
    @test !in(varname1, [varname2, varname3, :a, :b])
    @test isa(ex1, Expr)
    @test ex1 == :($(Expr(:escape, :a)))

    @test oex2 == :b
    @test isa(varname2, Symbol)
    @test !in(varname2, [varname1, varname3, :a, :b])
    @test isa(ex2, Expr)
    @test ex2 == :($(Expr(:escape, :b)))

    @test oex3 == :(a + b)
    @test isa(varname3, Symbol)
    @test !in(varname3, [varname1, varname2, :a, :b])
    @test isa(ex3, Expr)
    @test ex3 == :($varname1 + $varname2)
end

@testset "constant array expressions" begin
    origex = :( Any[] )
    newex, trace = split_in_subexpressions(origex)
    @test isa(newex, Expr)
    @test length(trace) == 0
end

end

#@testset "split_in_subexpressions" begin

#@testset "split_in_intermediate_exprs" begin
#
#
#
#end
#
#@testset "build_stepwise_value_context_expr" begin
#
#@testset "constant Int expression" begin
#    r = @stepwise 1
#    @test isa(r, Returned)
#    @test r.value == 1
#    @test length(r.context) == 0
#end
#
#@testset "constant String expression" begin
#    r = @stepwise "arne"
#    @test isa(r, Returned)
#    @test r.value == "arne"
#    @test length(r.context) == 0
#end
#
#@testset "constant Float64 expression" begin
#    r = @stepwise 42.56
#    @test isa(r, Returned)
#    @test r.value == 42.56
#    @test length(r.context) == 0
#end
#
#@testset "constant Array expressions" begin
#    r1 = @stepwise Any[]
#    @test isa(r1, Returned)
#    @test r1.value == Any[]
#    @test length(r1.context) == 1
#
#    r2 = @stepwise Any[1]
#    @test isa(r2, Returned)
#    @test r2.value == Any[1]
#    @test length(r2.context) == 1
#end
#
#@testset "true predicate with single var" begin
#    a = 1
#    r = @stepwise a == 1
#    @test isa(r, Returned)
#    @test r.value == true
#    @test length(r.context) == 2
#    c1 = r.context[1]
#    @test isa(c1, Tuple)
#    @test c1[1] == :a
#    @test c1[2] == 1
#    c2 = r.context[2]
#    @test isa(c2, Tuple)
#    @test c2[1] == :(a == 1)
#    @test c2[2] == true
#end
#
#@testset "false predicate with single var" begin
#    a = 4.0
#    r = @stepwise 2 == a
#    @test isa(r, Returned)
#    @test r.value == false
#    @test length(r.context) == 2
#    c1 = r.context[1]
#    @test isa(c1, Tuple)
#    @test c1[1] == :a
#    @test c1[2] == 4.0
#    c2 = r.context[2]
#    @test isa(c2, Tuple)
#    @test c2[1] == :(2 == a)
#    @test c2[2] == false
#end
#
#@testset "predicate with undefined var, empty context" begin
#    r = @stepwise b == 1
#    @test isa(r, Threw)
#    @test r.orig_expr == :(b == 1)
#    @test r.subexpr == :(b) # Subexpr for which exception was thrown
#    @test isa(r.exception, UndefVarError)
#    @test length(r.context) == 0
#end
#
#@testset "predicate with undefined var, non-empty context" begin
#    a = 42
#    r = @stepwise a == b
#    @test isa(r, Threw)
#    @test r.orig_expr == :(a == b)
#    @test r.subexpr == :(b) # Subexpr for which exception was thrown
#    @test isa(r.exception, UndefVarError)
#    @test length(r.context) == 1
#    c1 = r.context[1]
#    @test isa(c1, Tuple)
#    @test c1[1] == :a
#    @test c1[2] == 42
#end
#
#@testset "true predicate with three vars in array" begin
#    a = 1
#    b = 2
#    c = Any[a, b+a]
#    r = @stepwise c == Any[a, a+b]
#    #@show r
#    @test isa(r, Returned)
#    @test r.value == true
#    @test length(r.context) == 5
#    #c1 = r.context[1]
#    #@test isa(c1, Tuple)
#    #@test c1[1] == :a
#    #@test c1[2] == Any[1]
#    #c2 = r.context[2]
#    #@test isa(c2, Tuple)
#    #@test c2[1] == :(a == Any[1])
#    #@test c2[2] == true
#end
#
#end

end