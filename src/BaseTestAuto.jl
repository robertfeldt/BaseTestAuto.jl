"""
BaseTestAuto extends the Base.Test implementation from Julia 0.5.0-dev
with support for automated testing. It can be used as a drop-in replacement
but with support for test data generation, repeated testing etc.
"""
module BaseTestAuto

#
# We either use the orig part of base/test.jl, or we extend it. We possibly
# also read in new additions.
#

# Test results have a richer hierarchy since we add ValuesAssertions that checks
# their assertion based on multiple samples of the tested expression. Thus
# we change both the result types and the test macro and include the basic three
# types of assertions.
#include("orig_base_test_parts/test_result.jl")
#include("orig_base_test_parts/test_macro.jl")
#include("orig_base_test_parts/test_throws_macro.jl")
include("base_test_changes/test_result.jl")
include("assertion_types/test_assertion.jl")
include("assertion_types/test_assertion_base_api.jl")

include("assertion_types/predicate_true_assertion.jl")
#include("assertion_types/expected_value_assertion.jl")
#include("assertions/exception_thrown_assertion.jl")
include("assertion_types/accumulator_assertion.jl")

include("base_test_changes/test_macro.jl")
include("base_test_changes/test_throws_macro.jl")

include("orig_base_test_parts/abstract_testset.jl")

include("orig_base_test_parts/fallback_testset.jl")

#include("orig_base_test_parts/default_testset.jl")
include("base_test_changes/default_testset.jl")

include("orig_base_test_parts/testset_macros.jl")

#include("orig_base_test_parts/testset_helper_methods.jl")
include("base_test_changes/testset_helper_methods.jl")

include("orig_base_test_parts/legacy_testing_methods.jl")


# Fully new stuff
include(joinpath("utils", "traverse_expression.jl"))
include("stepwise_expr_evaluation.jl")

# Commonly used multi values assertions
include(joinpath("assertion_types", "common_multi_values_assertions.jl"))

# Export the same as exported by BaseTestNext
export @test, @test_throws, @testset
export @test_approx_eq, @test_approx_eq_eps, @inferred

end # BaseTestAuto module