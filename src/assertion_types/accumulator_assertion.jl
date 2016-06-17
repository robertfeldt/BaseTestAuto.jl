"""
    AccumulatorAssertion

Accumulates values on each checking invocation and then performs a final check
on the accumulated values.
"""
type AccumulatorAssertion <: MultiAssertion
    checkFn
    accumulator
    errormessageFn::Function
    firstsampled # We save the first sampled value since we might need to access the sampled expression in error reporting
    AccumulatorAssertion(checkFn::Function, acc = Any[], errormessageFn::Function = (acc) -> "") = begin
        new(checkFn, acc, errormessageFn, nothing)
    end
end

function check(a::AccumulatorAssertion, res::Returned)
    push!(a.accumulator, res.value)
    if a.firstsampled == nothing
        a.firstsampled = res
    end
    NoDecision() # we don't check the assertion while accumulating values
end

""" Apply the checking condition fn to the accumulated values to see if assertion fulfilled. """
function multicheck(a::AccumulatorAssertion)
    otype = outcome_type(a.checkFn(a.accumulator))
    otype(a, a.firstsampled)
end

# Convenience function to get what is shown on an IO back as a string.
function dump_to_string(v)
    io = IOBuffer()
    dump(io, v)
    strip(takebuf_string(io))
end

function errormessage(a::AccumulatorAssertion)
    errmsg = a.errormessageFn(a.accumulator)
    if length(errmessage) == 0
        errmessage = "The accumulated values does NOT fulfill the asserted condition!\nAccumulated values: $(dump_to_string(a.accumulator))"
    end
end

function Base.show(io::IO, a::AccumulatorAssertion, o::Fail)
    if isa(o.evaluationresult, Returned)
        errmessage = errormessage(a)
    else
        throw(ArgumentError("Don't know how to report on failure: ", o))
    end
    if isa(a.firstsampled, Returned)
        println(io, "Sampled expression: ", a.firstsampled.orig_expr)
    else
        println(io, "Expression was never sampled!")
    end
    println(io, errormessage)
end
