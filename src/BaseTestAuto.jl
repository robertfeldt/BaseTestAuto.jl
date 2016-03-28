"""
BaseTestAuto extends the Base.Test implementation from Julia 0.5.0-dev
with support for automated testing. It can be used as a drop-in replacement
but with support for test data generation, repeated testing etc.
"""
module BaseTestAuto

#
# We either use the orig part of base/test.jl unless we have extended it:
#

include("orig_base_test_parts/test_result.jl"),

include("orig_base_test_parts/test_macro.jl"),

include("orig_base_test_parts/test_throws_macro.jl"),

include("orig_base_test_parts/abstract_testset.jl"),

include("orig_base_test_parts/fallback_testset.jl"),

include("orig_base_test_parts/default_testset.jl"),

include("orig_base_test_parts/testset_macros.jl"),

#include("orig_base_test_parts/testset_helper_methods.jl"),
include("base_test_changes/testset_helper_methods.jl"),

include("orig_base_test_parts/legacy_testing_methods.jl")


# Fully new stuff
#include("extract_sub_expressions.jl")

# Export the same as exported by BaseTestNext
export @test, @test_throws, @testset
export @test_approx_eq, @test_approx_eq_eps, @inferred

end # BaseTestAuto module