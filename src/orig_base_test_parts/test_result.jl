"""
    Result

All tests produce a result object. This object may or may not be
'stored', depending on whether the test is part of a test set.
"""
abstract Result

"""
    Pass

The test condition was true, i.e. the expression evaluated to true or
the correct exception was thrown.
"""
immutable Pass <: Result
    test_type::Symbol
    orig_expr
    expr
    value
end
function Base.show(io::IO, t::Pass)
    print_with_color(:green, io, "Test Passed\n")
    print(io, "  Expression: ", t.orig_expr)
    if t.test_type == :test_throws
        # The correct type of exception was thrown
        print(io, "\n      Thrown: ", typeof(t.value))
    elseif !isa(t.expr, Expr)
        # Maybe just a constant, like true
        print(io, "\n   Evaluated: ", t.expr)
    elseif t.test_type == :test && t.expr.head == :comparison
        # The test was an expression, so display the term-by-term
        # evaluated version as well
        print(io, "\n   Evaluated: ", t.expr)
    end
end

"""
    Fail

The test condition was false, i.e. the expression evaluated to false or
the correct exception was not thrown.
"""
type Fail <: Result
    test_type::Symbol
    orig_expr
    expr
    value
end
function Base.show(io::IO, t::Fail)
    print_with_color(:red, io, "Test Failed\n")
    print(io, "  Expression: ", t.orig_expr)
    if t.test_type == :test_throws_wrong
        # An exception was thrown, but it was of the wrong type
        print(io, "\n    Expected: ", t.expr)
        print(io, "\n      Thrown: ", typeof(t.value))
    elseif t.test_type == :test_throws_nothing
        # An exception was expected, but no exception was thrown
        print(io, "\n    Expected: ", t.expr)
        print(io, "\n  No exception thrown")
    elseif !isa(t.expr, Expr)
        # Maybe just a constant, like false
        print(io, "\n   Evaluated: ", t.expr)
    elseif t.test_type == :test && t.expr.head == :comparison
        # The test was an expression, so display the term-by-term
        # evaluated version as well
        print(io, "\n   Evaluated: ", t.expr)
    end
end

"""
    Error

The test condition couldn't be evaluated due to an exception, or
it evaluated to something other than a `Bool`.
"""
type Error <: Result
    test_type::Symbol
    orig_expr
    value
    backtrace
end
function Base.show(io::IO, t::Error)
    print_with_color(:red, io, "Error During Test\n")
    if t.test_type == :test_nonbool
        println(io, "  Expression evaluated to non-Boolean")
        println(io, "  Expression: ", t.orig_expr)
        print(  io, "       Value: ", t.value)
    elseif t.test_type == :test_error
        println(io, "  Test threw an exception of type ", typeof(t.value))
        println(io, "  Expression: ", t.orig_expr)
        # Capture error message and indent to match
        errmsg = sprint(showerror, t.value, t.backtrace)
        print(io, join(map(line->string("  ",line),
                            split(errmsg, "\n")), "\n"))
    elseif t.test_type == :nontest_error
        # we had an error outside of a @test
        println(io, "  Got an exception of type $(typeof(t.value)) outside of a @test")
        # Capture error message and indent to match
        errmsg = sprint(showerror, t.value, t.backtrace)
        print(io, join(map(line->string("  ",line),
                            split(errmsg, "\n")), "\n"))
    end
end

