type ExceptionThrownAssertion <: TestAssertion
    exceptiontype::DataType
    options::AssertionOptions
    ExceptionThrownAssertion(extype::DataType) = new(extype, empty_assertion_options())
end

""" It is a failure if a value is returned since we are expecting an exception. """
function check(a::ExceptionThrownAssertion, res::Returned)
    Fail(a, res)
end

""" It is a pass if the correct exception is thrown, otherwise a fail. """
function check(a::ExceptionThrownAssertion, res::Threw)
    if isa(res.exception, a.exceptiontype)
        Pass(a, res)
    else
        Fail(a, res)
    end
end

function Base.show(io::IO, a::ExceptionThrownAssertion, o::Fail)
    if isa(o.evaluationresult, Returned)
        println(io, "Expected an exception of type $(a.exceptiontype) but a value ($(o.evaluationresult.value)) was returned")
    else
        println(io, "Expected an exception of type $(a.exceptiontype) but got an exception ($(o.evaluationresult.exception))")
    end
end
