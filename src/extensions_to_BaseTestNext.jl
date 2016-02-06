# We add two methods to AbstractTestSet to give more control to custom testsets
# that need it:
# start(AbstractTestSet, Int)
#   Called after the test set has been added to the test set stack and when
#     it's test is about to run.
# finishtestrun(AbstractTestSet, Int)
#   Called after each run of the tests in this test set.

"""
    start(ts::AbstractTestSet, iterations::Int)

Do any setup processing for the given testset. This is called by the 
`@testset` infrastructure before a test block executes with an `iterations` arg that
indicates the number of times the test block has been executed. One common use for this
function is to record the starting time for timing of testing. Its return value
indicates if the test block should actually be executed or not.
"""
function start(ts::AbstractTestSet, iterations::Int)
  if iterations < 1
    BaseTestAuto.RunTests     # Always run at least once
  else
    BaseTestAuto.DontRunTests # Default is to only run once, i.e. not when larger than 0
  end
end

# Default is to do nothing at the end of one run of the tests
finishtestrun(ts::AbstractTestSet, iterations::Int) = ts

abstract TestAction # To collect all the test action singleton types.
type RunTests <: TestAction; end # singleton that indicates one more execution of the test block of a test set
type DontRunTests <: TestAction; end # singleton that indicates no more execution of the test block of a test set


"""
Generate the code for a `@testset` with a `begin`/`end` argument.
This is based on the BaseTestNext.testset_beginend code but inserts
the calls to the extended interface to AbstractTestSet.
"""
function testset_beginend(args, tests)
    desc, testsettype, options = parse_testset_args(args[1:end-1])
    if desc == nothing
        desc = "test set"
    end
    # if we're at the top level we'll default to DefaultTestSet. Otherwise
    # default to the type of the parent testset
    if testsettype == nothing
        testsettype = :(get_testset_depth() == 0 ? DefaultTestSet : typeof(get_testset()))
    end

    # Generate a block of code that initializes a new testset, adds
    # it to the task local storage, evaluates the test(s), before
    # finally removing the testset and giving it a change to take
    # action (such as reporting the results)
    quote
        ts = $(testsettype)($desc; $options...)
        push_testset(ts)
        iters = 0
        while start(ts, iters) == BaseTestAuto.RunTests
            try
                $(esc(tests))
            catch err
                # something in the test block threw an error. Count that as an
                # error in this test set
                record(ts, Error(:nontest_error, :(), err, catch_backtrace()))
            end
            iters += 1
            finishtestrun(ts, iters)
        end
        pop_testset()
        finish(ts)
    end
end

"""
Generate the code for a `@testset` with a `for` loop argument
"""
function testset_forloop(args, testloop)
    # pull out the loop variables. We might need them for generating the
    # description and we'll definitely need them for generating the
    # comprehension expression at the end
    loopvars = Expr[]
    if testloop.args[1].head == :(=)
        push!(loopvars, testloop.args[1])
    elseif testloop.args[1].head == :block
        for loopvar in testloop.args[1].args
            push!(loopvars, loopvar)
        end
    else
        error("Unexpected argument to @testset")
    end

    desc, testsettype, options = parse_testset_args(args[1:end-1])

    if desc == nothing
        # No description provided. Generate from the loop variable names
        v = loopvars[1].args[1]
        desc = Expr(:string,"$v = ", esc(v)) # first variable
        for l = loopvars[2:end]
            v = l.args[1]
            push!(desc.args,", $v = ")
            push!(desc.args, esc(v))
        end
    end

    if testsettype == nothing
        testsettype = :(get_testset_depth() == 0 ? DefaultTestSet : typeof(get_testset()))
    end

    # Uses a similar block as for `@testset`, except that it is
    # wrapped in the outer loop provided by the user
    tests = testloop.args[2]
    blk = quote
        ts = $(testsettype)($desc; $options...)
        push_testset(ts)
        iters = 0
        while start(ts, iters) == BaseTestNext.RunTests
            try
                $(esc(tests))
            catch err
                # something in the test block threw an error. Count that as an
                # error in this test set
                record(ts, Error(:nontest_error, :(), err, catch_backtrace()))
            end
            pop_testset()
            iters += 1
            finishtestrun(ts, iters)
        end
        finish(ts)
    end
    Expr(:comprehension, blk, [esc(v) for v in loopvars]...)
end
