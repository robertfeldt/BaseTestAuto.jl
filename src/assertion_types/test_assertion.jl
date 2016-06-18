"""
    TestAssertion

A test assertion samples an expression and checks directly and/or based
on a (sub)set of multiple samples fulfill what is being asserted. 
If a decision cannot be taken it returns NoDecision, otherwise 
"""
abstract TestAssertion

"""
    DirectAssertion

Checks a sampled value directly and has no state.
"""
abstract DirectAssertion <: TestAssertion

"""
    MultiAssertion

Has state and samples multiple values of an expression before it 
can be (fully) checked.
"""
abstract MultiAssertion <: TestAssertion

"""
    EvaluationResult

Datum of this type is returned from the sampling expression used by a 
test assertion in the code its @test macro expands to.
"""
abstract EvaluationResult

"""
    Threw

Indicates that an `exception` was thrown when evaluating `sub_expr`
which as part of the `orig_expr` to be sampled. The context contains
a trace of the sub-expressions evaluated so far and what they evaluated
to.
"""
immutable Threw <: EvaluationResult
    orig_expr
    subexpr
    exception
    context
end

"""
    Returned

Type of values returned from the sampling expression used by a test assertion in the code
the @test macro expands to.
"""
immutable Returned <: EvaluationResult
    orig_expr
    value
    context
    Returned(expr, value, context = Any[]) = new(expr, value, context)
end
