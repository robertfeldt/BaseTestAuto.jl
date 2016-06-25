type PredicateTrueAssertion <: TestAssertion
    options::AssertionOptions
    PredicateTrueAssertion() = new(empty_assertion_options())
end

function transform_to_sampling_expression(::Type{Val{:PredicateTrueAssertion}}, expr::Expr)
    default_transform_to_sampling_expression(expr)
end

# Internal helper for creating Pass or Fail outcomes.
outcome_type(pred::Bool) = pred ? Pass : Fail

function check(a::PredicateTrueAssertion, res::Returned)
    otype = outcome_type(res.value == true)
    otype(a, res)
end

function report_value_mismatch(io::IO, expr, expected, actual, context)
    println(io, "Sampled expression: ", expr)
    println(io, "Actual value:       ", actual)
    println(io, "Expected value:     ", expected)
    print_context(io, context)
end

function print_context(io::IO, context, indent = 0)
    if length(context) > 0
        istr = " " ^ indent
        println(io, istr, "With subexpressions that evaluated to:")
        for (expr, value) in context
            println(io, istr, "  ", expr, " = ", esc_value(value))
        end
    end
end

esc_value(x) = x
esc_value(x::AbstractString) = "\"" * x * "\""

function Base.show(io::IO, a::PredicateTrueAssertion, o::Fail)
    if isa(o.evaluationresult, Returned)
        eres = o.evaluationresult
        actual = eres.value
        report_value_mismatch(io, eres.orig_expr, true, actual, eres.context)
    else
        throw(ArgumentError("Don't know how to report on failure: ", o))
    end
end
