"""
    FallbackTestSet

A simple fallback test set that throws immediately on a failure.
"""
immutable FallbackTestSet <: AbstractTestSet
end
fallback_testset = FallbackTestSet()

# Records nothing, and throws an error immediately whenever a Fail or
# Error occurs. Takes no action in the event of a Pass result
record(ts::FallbackTestSet, t::Pass) = t
function record(ts::FallbackTestSet, t::Union{Fail,Error})
    println(t)
    error("There was an error during testing")
end
# We don't need to do anything as we don't record anything
finish(ts::FallbackTestSet) = ts

