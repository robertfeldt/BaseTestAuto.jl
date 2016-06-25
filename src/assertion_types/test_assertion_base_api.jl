const EmptyContext = Any[]

# Default implementation which can be used in other transform functions, as a fallback.
function default_transform_to_sampling_expression(expr::Expr)
    orig_ex = Expr(:quote, expr)
    quote
        try
            return Returned($orig_ex, $expr, EmptyContext)
        catch _e
            return Threw($orig_ex, $orig_ex, _e, EmptyContext)
        end
    end
end

# If a test assertion have not implemented their own transformer we warn but then fall back
# on the default one.
function transform_to_sampling_expression(t, expr::Expr)
    warn("Using default sampling expression trasformer (function transform_to_sampling_expression) since no one defined for $t")
    default_transform_to_sampling_expression(expr)
end

const SingletonNoDecision = NoDecision()

""" Checking when an exception was raised by default leads to a test error. """
function check(ta::TestAssertion, er::Threw)
    Error(ta, er, :test_error, backtrace())
end

""" Checking when a value was sampled should be implemented by all assertions even though
    MultiSamplesAssertions might not take a decision. """
function check(ta::TestAssertion, er::Result)
    throw(ArgumentError("To Be Implemented: check for $ta"))
end

""" A direct assertion has no state so takes no decision when checked without a sampled value. """
function multicheck(ta::DirectAssertion)
    SingletonNoDecision
end

""" Default is that an assertion is never finalized, i.e. can always accept more values that
    might affects its status. """
isfinalized(ta::TestAssertion) = false

""" Assertions can have options. """
typealias AssertionOptions Dict{Symbol, Any}

empty_assertion_options() = Dict{Symbol, Any}()

function set_options(ta::TestAssertion, options::AssertionOptions)
    if in(:options, fieldnames(ta))
        for (key, val) in options
            ta.options[key] = val
        end
    else
        throw(ArgumentError("Trying to set options on a test assertion (of type $(typeof(ta))) that has no options field"))
    end
end

# Short hand getters for common options
shouldskip(ta::TestAssertion) = get(ta.options, :skip, false)
isbroken(ta::TestAssertion) = get(ta.options, :broken, false)
file(ta::TestAssertion) = get(ta.options, :file, "<unknown file>")
line(ta::TestAssertion) = get(ta.options, :line, "<unknown line>")

#
# Default ways of reporting on assertion outcomes
#
function Base.show(io::IO, a::TestAssertion, t::Error)
    if t.error_type == :test_nonbool
        println(io, "  Expression evaluated to non-Boolean")
        println(io, "  Expression: ", t.orig_expr)
        print(  io, "       Value: ", t.value)
    elseif t.error_type == :test_error
        evres = t.evaluationresult
        println(io, "  Test threw an exception of type ", typeof(evres.exception))
        println(io, "  In expression:   ", evres.orig_expr)
        println(io, "  When evaluating: ", evres.subexpr)
        print_context(io, evres.context, 4)
        # Capture error message and indent to match
        errmsg = sprint(showerror, evres.exception, t.backtrace)
        print(io, join(map(line->string("  ",line),
                            split(errmsg, "\n")), "\n"))
    elseif t.error_type == :nontest_error
        # we had an error outside of a @test
        println(io, "  Got an exception of type $(typeof(t.value)) outside of a @test")
        # Capture error message and indent to match
        errmsg = sprint(showerror, t.value, t.backtrace)
        print(io, join(map(line->string("  ",line),
                            split(errmsg, "\n")), "\n"))
    end
end

function Base.show(io::IO, a::TestAssertion, t::Pass)
    # Since it was a pass we do not detail why it passed...
    print(io, "  Expression: ", t.evaluationresult.orig_expr)
end

expected_value(ta::TestAssertion) = nothing

function Base.show(io::IO, a::TestAssertion, t::Fail)
    evres = t.evaluationresult
    print(io,   "  Expression: ", evres.orig_expr)
    expr = evaluated_expr(evres.orig_expr, evres.context)
    print(io, "\n   Evaluated: ", expr)
    print(io, "\n      Actual: ", evres.value)
    if !isa(expected_value(a), Void)
        print(io, "\n    Expected: ", expected_value(a))
    end
end
