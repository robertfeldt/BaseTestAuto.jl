# Dispatch on constant symbol

abstract EvaluationResult

immutable Threw <: EvaluationResult
    orig_expr
    exception
end

immutable SubExprThrew <: EvaluationResult
    orig_expr
    subexpr
    exception
    context
end

immutable Returned <: EvaluationResult
    orig_expr
    value
    context
end

# Default implementation is to just capture the top-level exception
function default_eval_expr(expr::Expr)
    orig_ex = Expr(:quote, expr)
    quote
        try
            return Returned($orig_ex, $expr, Any[])
        catch _e
            return Threw($orig_ex, _e)
        end
    end
end

function eval_expr(t, expr::Expr)
    warn("No eval_expr specified for $t")
    default_eval_expr(expr)
end

function eval_expr(::Type{Val{:PredicateTrueAssertion}}, expr::Expr)
    default_eval_expr(expr)
end

const LhsId = gensym()
const RhsId = gensym()

function eval_expr(::Type{Val{:ComparisonAssertion}}, expr::Expr)
    @assert expr.head == :comparison
    orig_ex = Expr(:quote, expr)
    lhs = expr.args[1]
    orig_lhs = Expr(:quote, lhs)
    op = expr.args[2]
    rhs = expr.args[3]
    orig_rhs = Expr(:quote, rhs)
    nexpr = Expr(:comparison, :lhs, op, :rhs)
    quote
        begin
            local lhs, rhs
            context = Any[]
            try
                lhs = ($lhs)
                push!(context, (LhsId, lhs))
            catch _e
                return SubExprThrew($orig_ex, $orig_lhs, _e, context)
            end
            try
                rhs = ($rhs)
                push!(context, (RhsId, rhs))
            catch _e
                return SubExprThrew($orig_ex, $orig_rhs, _e, context)
            end
            try
                value = $nexpr
                return Returned($orig_ex, value, context)
            catch _e
                return Threw($orig_ex, _e)
            end
        end
    end
end

abstract TestAssertion

type PredicateTrueAssertion <: TestAssertion; end
type ComparisonAssertion <: TestAssertion
    op
end

function check(t::TestAssertion, res::Returned)
    if (res.value == true)
        (:pass)
    else
        (:fail, "$(res.orig_expr) evaluated to $(res.value) but we expected it to be true")
    end
end

function lookup_context(context, key)
    idx = findfirst(t -> t[1] == key, context)
    if isa(idx, Integer)
        context[idx][2]
    else
        nothing
    end
end

function check(t::ComparisonAssertion, res::Returned)
    if (res.value == true)
        (:pass)
    else
        (:fail, "$(lookup_context(res.context, LhsId)) $(t.op) $(lookup_context(res.context, RhsId)) evaluated to $(res.value)")
    end
end

function check(t::TestAssertion, res::SubExprThrew)
    (:error, "Exception $(res.exception) was raised when evaluating\n  sub expression: $(res.subexpr)\n  in expression: $(res.orig_expr)")
end

function check(t::TestAssertion, res::Threw)
    (:error, "Exception $(res.exception) was raised when evaluating $(res.orig_expr)")
end

a = 2
ex = :( a == 1 )

ptex = eval_expr(Val{:PredicateTrueAssertion}, ex)
pres = eval(ptex)
println(check(PredicateTrueAssertion(), pres)[2])

ctex = eval_expr(Val{:ComparisonAssertion}, ex)
cres = eval(ctex)
println(check(ComparisonAssertion(:(==)), cres)[2])

# Exception thrown in lhs
function te(e)
    throw(ArgumentError("Missing"))
end

ex = :( te(1) == 1 )

ptex = eval_expr(Val{:PredicateTrueAssertion}, ex)
pres = eval(ptex)
check(PredicateTrueAssertion(), pres)

ctex = eval_expr(Val{:ComparisonAssertion}, ex)
cres = eval(ctex)
check(ComparisonAssertion(:(==)), cres)

# Lets implement the basics of a performance assertion. It will evaluate the expression
# while measuring the time taken and then ensure it is below some target value.
type PerformanceAssertion <: TestAssertion
    maxtime::Float64
end

immutable ReturnedP <: EvaluationResult
    orig_expr
    value
    elapsed
end

function eval_expr(::Type{Val{:PerformanceAssertion}}, expr::Expr)
    orig_ex = Expr(:quote, expr)
    quote
        try
            st = time()
            value = $expr
            et = time()
            return ReturnedP($orig_ex, value, et-st)
        catch _e
            return Threw($orig_ex, _e)
        end
    end
end

function formattime(t)
    if t <= 5e-2
        string(round(t/1e-3, 2)) * " ms"
    elseif t >= 60.0
        string(round(t/60.0, 2)) * " mins"
    else
        string(round(t, 2)) * " s"
    end
end

function check(t::PerformanceAssertion, res::ReturnedP)
    if (res.elapsed < t.maxtime)
        (:pass)
    else
        hr = format_time(res.elapsed)
        (:fail, "Execution time was $hr which is more than expected $(t.maxtime)")
    end
end

function fut(n)
    sum = 0.0
    for i in 1:n
        sum += i
    end
    sum
end

a = 2e5
ex = :( fut(a) )

petex = eval_expr(Val{:PerformanceAssertion}, ex)
peres = eval(petex)
println(check(PerformanceAssertion(1e-2), peres)[2])
