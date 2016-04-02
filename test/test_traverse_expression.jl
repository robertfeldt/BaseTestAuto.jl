@testset "traverse_expr" begin

accumulate_vars(s::Symbol, a) = in(s, a) ? (s, a) : (s, push!(a, s))
accumulate_vars(e, a) = (e, a)

@testset "accumulate vars, no update" begin
    ex = :(1)
    r1 = traverse_expr(ex, accumulate_vars, Any[])
    @test r1 == (ex, Any[])

    ex = :(a)
    r2 = traverse_expr(:(a), accumulate_vars, Any[])
    @test r2 == (ex, Any[:a])

    ex = :(a + b)
    r3 = traverse_expr(ex, accumulate_vars, Any[])
    @test r3 == (ex, Any[:a, :b])

    ex = :(a + 1 / (b * c))
    r4 = traverse_expr(ex, accumulate_vars, Any[])
    @test r4 == (ex, Any[:a, :b, :c])
end

@testset "dont accumulate keyword arg names as vars" begin
    ex = :( f(1, y=2) )
    r = traverse_expr(ex, accumulate_vars, Any[])
    @test r == (ex, Any[])
end

@testset "dont accumulate field refs as vars" begin
    ex = :( a.b )
    r = traverse_expr(ex, accumulate_vars, Any[])
    @test r == (ex, Any[:a])
end

function accvars_and_update(s::Symbol, a)
    add1(s) = symbol(string(s) * "1")
    if in(s, a)
        (add1(s), a)
    else
        (add1(s), push!(a, s))
    end
end
accvars_and_update(e, a) = (e, a)

@testset "accumulate vars and update" begin
    ex = :(1.5)
    r1 = traverse_expr(ex, accvars_and_update, Any[]; update = true)
    @test r1 == (ex, Any[])

    ex = :(a)
    r2 = traverse_expr(:(a), accvars_and_update, Any[]; update = true)
    @test r2 == (:(a1), Any[:a])

    ex = :(a + b)
    r3 = traverse_expr(ex, accvars_and_update, Any[]; update = true)
    @test r3 == (:(a1 + b1), Any[:a, :b])

    ex = :(a + 1 / (b * c))
    r4 = traverse_expr(ex, accvars_and_update, Any[]; update = true)
    @test r4 == (:(a1 + 1 / (b1 * c1)), Any[:a, :b, :c])
end

iscall(ex) = isa(ex, Expr) && ex.head == :call

@testset "filter expr" begin
    @test iscall(:(fn(1))) == true
    @test iscall(:(a))     == false

    ex = :(a + b)
    @test iscall(ex)       == true
    r = filter(iscall, ex)
    @test r == Any[ex]

    ex2 = :( f1(1, f2(f3(1)), f4(f5())) )
    r2 = filter(iscall, ex2)
    @test r2 == Any[:(f3(1)), :(f2(f3(1))), :(f5()), :(f4(f5())), ex2]
end

# Accumulate variables and calls while substituting them for temp var names.
function acc_vars_and_calls_insert_tempvars(s::Symbol, acc)
    tvar = subst_expr!(acc, s, gensym(), esc(s))
    (tvar, acc)
end
function acc_vars_and_calls_insert_tempvars(e::Expr, acc)
    if iscall(e)
        tvar = subst_expr!(acc, e, gensym(), e)
        (tvar, acc)
    else
        (e, acc)
    end
end
acc_vars_and_calls_insert_tempvars(e, acc) = (e, acc) # For literals and other node types

function subst_expr!(context, orig_ex, tempvar, ex)
  idx = findfirst(t -> t[1] == orig_ex, context)
  if idx > 0
    return context[idx][2]
  else
    push!(context, (orig_ex, tempvar, ex))
    return tempvar
  end
end

@testset "accumulate vars and calls while substituting" begin
    ex = :(1.5)
    r1 = traverse_expr(ex, acc_vars_and_calls_insert_tempvars; update = true)
    @test r1 == (ex, Any[])

    ex2 = :(f(1))
    r2 = traverse_expr(ex2, acc_vars_and_calls_insert_tempvars; update = true)
    @test isa(r2[1], Symbol)
    @test length(r2[2]) == 1
    origex, tvar, substexpr = r2[2][1]
    @test origex == ex2
    @test isa(tvar, Symbol)
    @test substexpr == ex2

    ex3 = :(f(a))
    r3 = traverse_expr(ex3, acc_vars_and_calls_insert_tempvars; update = true)
    @test isa(r3[1], Symbol)
    @test length(r3[2]) == 2

    origex, tvar, substexpr = r3[2][1]
    @test origex == :(a)
    @test isa(tvar, Symbol)
    @test substexpr == esc(:(a))

    origex2, tvar2, substexpr2 = r3[2][2]
    @test origex2 == :(f($tvar))
    @test isa(tvar2, Symbol)
    @test substexpr2 == :(f($tvar))
end

end
