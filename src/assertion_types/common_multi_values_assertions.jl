""" Array `ary` includes all values of array `included` """
includes_values(ary, included) = all(i -> in(i, ary), included)

""" Ensure that accumulated values includes at least the expected ones (but can 
    incl other values). """
function values_include(expectedValues::Vector)
    expvs = unique(expectedValues)
    has_all_expected_values(vs) = includes_values(vs, expvs)
    AccumulatorAssertion(has_all_expected_values, Set{Any}())
end

""" Ensure that a certain set of values been accumulated but disregard in what order. """
function values_are(expectedValues::Vector)
    has_only_expected_values(vs) = length(vs) == length(expectedValues) && includes_values(vs, expectedValues)
    AccumulatorAssertion(has_only_expected_values, Any[])
end

""" Ensure that at least 2 different values has been accumulated. """
function values_vary()
    AccumulatorAssertion((vs) -> length(vs) >= 2, Set{Any}())
end

""" Ensure that it takes a certain value at least once. """
function sometimes_equals(value)
    AccumulatorAssertion((vs) -> in(value, vs), Set{Any}())
end
