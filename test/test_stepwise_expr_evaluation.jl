using BaseTestAuto: subst_expr!, split_in_subexpressions
using BaseTestAuto: build_stepwise_value_context_expr, Returned, Threw

macro stepwise_eval(expr)
    stepwiseexpr = build_stepwise_value_context_expr(expr)
    #@show expr stepwiseexpr
    stepwiseexpr
end

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

@testset "build_stepwise_value_context_expr" begin

@testset "constant Int expression" begin
    r = @stepwise_eval 1
    @test isa(r, Returned)
    @test r.value == 1
    @test length(r.context) == 0
end

@testset "constant Float expression" begin
    r = @stepwise_eval 2.35
    @test isa(r, Returned)
    @test r.value == 2.35
    @test length(r.context) == 0
end

@testset "constant String expression" begin
    r = @stepwise_eval "arne"
    @test isa(r, Returned)
    @test r.value == "arne"
    @test length(r.context) == 0
end

@testset "constant Array expressions" begin
    r1 = @stepwise_eval Any[]
    @test isa(r1, Returned)
    @test r1.value == Any[]
    @test length(r1.context) == 0

    r2 = @stepwise_eval Any[1]
    @test isa(r2, Returned)
    @test r2.value == Any[1]
    @test length(r2.context) == 0
end

@testset "true predicate with single var" begin
    a = 1
    r = @stepwise_eval a == 1
    @test isa(r, Returned)
    @test r.value == true
    @test length(r.context) == 1

    c1 = r.context[1]
    @test isa(c1, Tuple)
    @test c1[1] == :a
    @test c1[2] == 1
end

@testset "false predicate with two vars" begin
    a = 2
    b = 2.45
    r = @stepwise_eval a >= b
    @test isa(r, Returned)
    @test r.value == false
    @test length(r.context) == 2

    c1 = r.context[1]
    @test isa(c1, Tuple)
    @test c1[1] == :a
    @test c1[2] == 2

    c2 = r.context[2]
    @test isa(c2, Tuple)
    @test c2[1] == :b
    @test c2[2] == 2.45
end

@testset "predicate with undefined var, empty context" begin
    r = @stepwise_eval c == 1
    @test isa(r, Threw)
    @test r.orig_expr == :(c == 1)
    @test r.subexpr == :(c) # Subexpr for which exception was thrown
    @test isa(r.exception, UndefVarError)
    @test length(r.context) == 0
end

@testset "predicate with undefined var, non-empty context" begin
    a = 42
    r = @stepwise_eval a == d
    @test isa(r, Threw)
    @test r.orig_expr == :(a == d)
    @test r.subexpr == :(d) # Subexpr for which exception was thrown
    @test isa(r.exception, UndefVarError)
    @test length(r.context) == 1

    c1 = r.context[1]
    @test isa(c1, Tuple)
    @test c1[1] == :a
    @test c1[2] == 42
end

@testset "true predicate with three vars partly in array" begin
    a = 1
    b = 2
    c = Any[a, b+a]
    r = @stepwise_eval Any[a, a+b] == c

    @test isa(r, Returned)
    @test r.value == true
    @test length(r.context) == 4

    c1 = r.context[1]
    @test isa(c1, Tuple)
    @test c1[1] == :a
    @test c1[2] == 1

    c2 = r.context[2]
    @test isa(c2, Tuple)
    @test c2[1] == :b
    @test c2[2] == 2

    c3 = r.context[3]
    @test isa(c3, Tuple)
    @test c3[1] == :(a + b)
    @test c3[2] == 3

    c4 = r.context[4]
    @test isa(c4, Tuple)
    @test c4[1] == :c
    @test c4[2] == Any[1, 3]
end

@testset "false predicate, func call" begin
    a = 1
    f(x) = x+1
    r = @stepwise_eval f(a) == 3

    @test isa(r, Returned)
    @test r.value == false
    @test length(r.context) == 2

    c1 = r.context[1]
    @test isa(c1, Tuple)
    @test c1[1] == :a
    @test c1[2] == 1

    c2 = r.context[2]
    @test isa(c2, Tuple)
    @test c2[1] == :(f(a))
    @test c2[2] == 2
end

@testset "true predicate, func call, const expressions and vars" begin
    a = 1
    b = 2.3
    f(x) = x+1
    g(x) = x^2
    r = @stepwise_eval g(f(a)+b) > (1+1+2.2)^2 

    @test isa(r, Returned)
    @test r.value == true
    @test length(r.context) == 7

    c1 = r.context[1]
    @test isa(c1, Tuple)
    @test c1[1] == :a
    @test c1[2] == 1

    c2 = r.context[2]
    @test isa(c2, Tuple)
    @test c2[1] == :(f(a))
    @test c2[2] == 2

    c3 = r.context[3]
    @test isa(c3, Tuple)
    @test c3[1] == :(b)
    @test c3[2] == 2.3

    c4 = r.context[4]
    @test isa(c4, Tuple)
    @test c4[1] == :(f(a) + b)
    @test c4[2] == 4.3

    c5 = r.context[5]
    @test isa(c5, Tuple)
    @test c5[1] == :(g(f(a) + b))
    @test c5[2] == (4.3^2)

    c6 = r.context[6]
    @test isa(c6, Tuple)
    @test c6[1] == :(1+1+2.2)
    @test c6[2] == (1+1+2.2)

    c7 = r.context[7]
    @test isa(c7, Tuple)
    @test c7[1] == :((1+1+2.2) ^ 2)
    @test c7[2] == (1+1+2.2)^2
end

@testset "exception in func call, no vars" begin
    f(x) = (x < 2) ? throw(ArgumentError("some problem")) : x+1
    r = @stepwise_eval f(0) == 1
    @test isa(r, Threw)
    @test r.orig_expr == :(f(0) == 1)
    @test r.subexpr == :(f(0)) # Subexpr for which exception was thrown
    @test isa(r.exception, ArgumentError)
    @test length(r.context) == 0
end

@testset "exception in func call, one var" begin
    a = 1
    f(x) = (x < 2) ? throw(ArgumentError("some problem")) : x+1
    r = @stepwise_eval f(a) == 2

    @test isa(r, Threw)
    @test r.orig_expr == :(f(a) == 2)
    @test r.subexpr == :(f(a)) # Subexpr for which exception was thrown
    @test isa(r.exception, ArgumentError)
    @test length(r.context) == 1

    c1 = r.context[1]
    @test isa(c1, Tuple)
    @test c1[1] == :a
    @test c1[2] == 1
end

@testset "exception in func call, many levels and vars" begin
    a = 1
    b = 3.4
    f(x) = (x < 2) ? throw(ArgumentError("some problem")) : x+1
    g(x) = x^2
    expected = (1+1+3.4)^2
    r = @stepwise_eval g(f(a)+b) == expected

    @test isa(r, Threw)
    @test r.orig_expr == :(g(f(a)+b) == expected)
    @test r.subexpr == :(f(a)) # Subexpr for which exception was thrown
    @test isa(r.exception, ArgumentError)
    @test length(r.context) == 1

    c1 = r.context[1]
    @test isa(c1, Tuple)
    @test c1[1] == :a
    @test c1[2] == 1
end

end

end

end