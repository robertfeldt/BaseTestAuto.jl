""" When an assertion is tested it has an outcome. """
abstract TestOutcome

"""
    NoDecision

A test might not (yet) be able to take a decision,
e.g. when it needs more values or when it has already taken a decision.
"""
type NoDecision <: TestOutcome; end

"""
    Result

When a test can take a decision it returns a Result object. 
This object may or may not be 'stored', depending on whether 
the test is part of a test set.
"""
abstract Result <: TestOutcome

"""
    Pass

The test condition was true, e.g. the expression evaluated to true or
the correct exception was thrown.
"""
immutable Pass <: Result
    testassertion
    evaluationresult
end
function Base.show(io::IO, t::Pass)
    print_with_color(:green, io, "Test Passed\n")
    show(io, t.testassertion, t)
    #print(io, "  Expression: ", t.orig_expr)
    #if t.test_type == :test_throws
    #    # The correct type of exception was thrown
    #    print(io, "\n      Thrown: ", typeof(t.value))
    #elseif !isa(t.expr, Expr)
    #    # Maybe just a constant, like true
    #    print(io, "\n   Evaluated: ", t.expr)
    #elseif t.test_type == :test && t.expr.head == :comparison
    #    # The test was an expression, so display the term-by-term
    #    # evaluated version as well
    #    print(io, "\n   Evaluated: ", t.expr)
    #end
end

"""
    Fail

The test condition was false, i.e. the expression evaluated to false or
the correct exception was not thrown.
"""
type Fail <: Result
    testassertion
    evaluationresult
end
function Base.show(io::IO, t::Fail)
    print_with_color(:red, io, "Test Failed\n")
    show(io, t.testassertion, t)
end

"""
    Error

The test condition couldn't be evaluated due to an exception.
"""
type Error <: Result
    testassertion
    evaluationresult
    error_type
    backtrace
end
function Base.show(io::IO, t::Error)
    print_with_color(:red, io, "Error During Test\n")
    Base.show(io, t.testassertion, t)
end
