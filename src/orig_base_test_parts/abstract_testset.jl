# The AbstractTestSet interface is defined by three methods:
# record(AbstractTestSet, Result)
#   Called by do_test after a test is evaluated
# should_run(AbstractTestSet, Int)
#   Called after the test set has been pushed onto the test set stack
#   and right before executing the tests. Should return true as long we should
#   continue running the tests. The 2nd argument is a counter of how many
#   times the tests in this testset have run so far.
# finish(AbstractTestSet)
#   Called after the test set has been popped from the test set stack
abstract AbstractTestSet

"""
    record(ts::AbstractTestSet, res::Result)

Record a result to a testset. This function is called by the `@testset`
infrastructure each time a contained `@test` macro completes, and is given the
test result (which could be an `Error`). This will also be called with an `Error`
if an exception is thrown inside the test block but outside of a `@test` context.
"""
function record end

"""
    should_run(ts::AbstractTestSet, nruns::Int)

Decide if the tests should be run; returns true if and only if they should.
The tests are called in a loop and the `nruns` arg counts the number of times the test
block has been executed. `nruns` is 0 when the tests have not yet executed.
"""
function should_run(ts::AbstractTestSet, nruns::Int)
    nruns < 1 # Default is to only run tests once, i.e. when num previous runs < 1
end

"""
    finish(ts::AbstractTestSet)

Do any final processing necessary for the given testset. This is called by the
`@testset` infrastructure after a test block executes. One common use for this
function is to record the testset to the parent's results list, using
`get_testset`.
"""
function finish end

"""
    TestSetException

Thrown when a test set finishes and not all tests passed.
"""
type TestSetException <: Exception
    pass::Int
    fail::Int
    error::Int
end

function Base.show(io::IO, ex::TestSetException)
    print(io, "Some tests did not pass: ")
    print(io, ex.pass,  " passed, ")
    print(io, ex.fail,  " failed, ")
    print(io, ex.error, " errored.")
end

