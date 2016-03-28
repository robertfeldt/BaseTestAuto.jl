"""
    @testset [CustomTestSet] [option=val  ...] ["description"] begin ... end
    @testset [CustomTestSet] [option=val  ...] ["description \$v"] for v in (...) ... end
    @testset [CustomTestSet] [option=val  ...] ["description \$v, \$w"] for v in (...), w in (...) ... end

Starts a new test set, or multiple test sets if a `for` loop is provided.

If no custom testset type is given it defaults to creating a `DefaultTestSet`.
`DefaultTestSet` records all the results and, and if there are any `Fail`s or
`Error`s, throws an exception at the end of the top-level (non-nested) test set,
along with a summary of the test results.

Any custom testset type (subtype of `AbstractTestSet`) can be given and it will
also be used for any nested `@testset` invocations. The given options are only
applied to the test set where they are given. The default test set type does
not take any options.

The description string accepts interpolation from the loop indices.
If no description is provided, one is constructed based on the variables.

By default the `@testset` macro will return the testset object itself, though
this behavior can be customized in other testset types. If a `for` loop is used
then the macro collects and returns a list of the return values of the `finish`
method, which by default will return a list of the testset objects used in
each iteration.
"""
macro testset(args...)
    isempty(args) && error("No arguments to @testset")

    tests = args[end]

    # Determine if a single block or for-loop style
    if !isa(tests,Expr) || (tests.head != :for && tests.head != :block)
        error("Expected begin/end block or for loop as argument to @testset")
    end

    if tests.head == :for
        return testset_forloop(args, tests)
    else
        return testset_beginend(args, tests)
    end
end

"""
Generate the code for a `@testset` with a `begin`/`end` argument
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

    testset_code_expr(testsettype, desc, options, tests)
end

# Generate a block of code that initializes a new testset, adds
# it to the task local storage, evaluates the test(s), before
# finally removing the testset and giving it a change to take
# action (such as reporting the results)
function testset_code_expr(testsettype, desc, options, tests)
    quote
        ts = $(testsettype)($desc; $options...)
        push_testset(ts)
        nruns = 0
        while should_run(ts, nruns)
            try
                $(esc(tests))
            catch err
                # something in the test block threw an error. Count that as an
                # error in this test set
                record(ts, Error(:nontest_error, :(), err, catch_backtrace()))
            end
            nruns += 1
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
    blk = testset_code_expr(testsettype, desc, options, tests)
    Expr(:comprehension, blk, [esc(v) for v in loopvars]...)
end

"""
Parse the arguments to the `@testset` macro to pull out the description,
Testset Type, and options. Generally this should be called with all the macro
arguments except the last one, which is the test expression itself.
"""
function parse_testset_args(args)
    desc = nothing
    testsettype = nothing
    options = :(Dict{Symbol, Any}())
    for arg in args[1:end]
        # a standalone symbol is assumed to be the test set we should use
        if isa(arg, Symbol)
            testsettype = esc(arg)
        # a string is the description
        elseif isa(arg, AbstractString) || (isa(arg, Expr) && arg.head == :string)
            desc = esc(arg)
        # an assignment is an option
        elseif isa(arg, Expr) && arg.head == :(=)
            # we're building up a Dict literal here
            key = Expr(:quote, arg.args[1])
            push!(options.args, Expr(:(=>), key, arg.args[2]))
        else
            error("Unexpected argument $arg to @testset")
        end
    end

    (desc, testsettype, options)
end

