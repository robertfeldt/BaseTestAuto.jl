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

@testset "filter expr" begin
    iscall(ex) = isa(ex, Expr) && ex.head == :call
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

end
