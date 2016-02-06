"""
Alternative BaseTestNext implementation which copies most of it and then
extends it to support repetition and automated test data generation:

* `@multitest`
* `@generate`

The default, task-level test set will repeat the tests in a block if there
are calls to the generate macro among their tests.
"""
module BaseTestAuto

# Dirty hack for now since I found no way to reuse most of it while still
# redefining the testset_beginend and testset_forloop methods. TOFIX!
include("parts_from_BaseTestNext.jl")

# Extend the base code with the minor changes needed to create the hooks we want
# for more powerful automated testing. Over time we hope that these extensions
# will be added to BaseTestNext and potentially Base.Test so we need not copy-paste
# that code like we currently do.
include("extensions_to_BaseTestNext.jl")

# Export the same as exported by BaseTestNext
export @test, @test_throws, @testset
export @test_approx_eq, @test_approx_eq_eps, @inferred

# And now start adding our new stuff.
include("multitest.jl")

end # BaseTestAuto module