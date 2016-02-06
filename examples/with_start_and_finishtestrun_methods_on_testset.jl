using BaseTestAuto
const Test = BaseTestAuto

# Let's create a (dummy) custom test set that times test execution and
# repeats the tests 30 times.
type FixedRepeatingTestSet <: BaseTestAuto.AbstractTestSet
    description::AbstractString
    results::Vector
    anynonpass::Bool
    initer::Int64
    starttime::Float64
    laststoptime::Float64
end
FixedRepeatingTestSet(desc) = FixedRepeatingTestSet(desc, [], false, -1, 0.0, 0.0)

import BaseTestAuto.record
# For a passing result, simply store the result
record(ts::FixedRepeatingTestSet, t::BaseTestAuto.Pass) = (push!(ts.results, t); t)

# For the other result types, immediately print the error message
# but do not terminate. Print a backtrace.
function record(ts::FixedRepeatingTestSet, t::Union{BaseTestAuto.Fail,BaseTestAuto.Error})
    print_with_color(:white, ts.description, ": ")
    print(t)
    # don't print the backtrace for Errors because it gets printed in the show
    # method
    isa(t, BaseTestAuto.Error) || Base.show_backtrace(STDOUT, backtrace())
    println()
    push!(ts.results, t)
    t
end

# When a FixedRepeatingTestSet finishes, it records itself to its parent
# testset, if there is one. This allows for recursive printing of
# the results at the end of the tests
record(ts::FixedRepeatingTestSet, t::BaseTestAuto.AbstractTestSet) = push!(ts.results, t)

# Continue running tests 30 times. Save the start time if this is the first iteration.
import BaseTestAuto.start
function start(ts::FixedRepeatingTestSet, iterations::Int)
    ts.initer = iterations
    if iterations < 1
      ts.starttime = time()
    end
    if iterations < 30
        println("Starting iteration $(iterations)!")
        BaseTestAuto.RunTests
    else
        BaseTestAuto.DontRunTests # Default is to only run once, i.e. not when larger than 0
    end
end

# Called at the end of a @testset, behaviour depends on whether
# this is a child of another testset, or the "root" testset
import BaseTestAuto.finish
function finish(ts::FixedRepeatingTestSet)
    ts.laststoptime = time()
    # If we are a nested test set, do not print a full summary
    # now - let the parent test set do the printing
    if BaseTestAuto.get_testset_depth() != 0
        # Attach this test set to the parent test set
        parent_ts = BaseTestAuto.get_testset()
        record(parent_ts, ts)
        return
    end

    numfinished = ts.initer+1
    if numfinished >= 30
      elapsed_time = ts.laststoptime - ts.starttime
      println("Executed the test block $(numfinished) times in $(elapsed_time) seconds")
      println(@sprintf("  %.2f test results/sec", length(ts.results)/elapsed_time))
    end

    # return the testset so it is returned from the @testset macro
    ts
end

@testset FixedRepeatingTestSet "Set 1" begin
  f(x) = x+1
  a = 1
  @test f(0) == a
  #@testset "Set 1.1 nested" begin
  #  @test (f(a)+1) == 1
  #end

  # A better example is to find some rare bug with random generation of test data.
  # Here we seed a bug to ensure there is one...
  myreverse(v) = length(v) > 1 ? reverse(v) : [1] # Bug happens only if length is 0
  len = rand(0:10) # This might not be found if only one repetition of test...
  v = randn(len)
  @test length(myreverse(v)) == length(v)
end