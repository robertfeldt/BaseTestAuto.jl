# Legacy approximate testing functions, yet to be included

approx_full(x::AbstractArray) = x
approx_full(x::Number) = x
approx_full(x) = full(x)

function test_approx_eq(va, vb, Eps, astr, bstr)
    va = approx_full(va)
    vb = approx_full(vb)
    if length(va) != length(vb)
        error("lengths of ", astr, " and ", bstr, " do not match: ",
              "\n  ", astr, " (length $(length(va))) = ", va,
              "\n  ", bstr, " (length $(length(vb))) = ", vb)
    end
    diff = real(zero(eltype(va)))
    for i = 1:length(va)
        xa = va[i]; xb = vb[i]
        if isfinite(xa) && isfinite(xb)
            diff = max(diff, abs(xa-xb))
        elseif !isequal(xa,xb)
            error("mismatch of non-finite elements: ",
                  "\n  ", astr, " = ", va,
                  "\n  ", bstr, " = ", vb)
        end
    end

    if !isnan(Eps) && !(diff <= Eps)
        sdiff = string("|", astr, " - ", bstr, "| <= ", Eps)
        error("assertion failed: ", sdiff,
              "\n  ", astr, " = ", va,
              "\n  ", bstr, " = ", vb,
              "\n  difference = ", diff, " > ", Eps)
    end
end

array_eps{T}(a::AbstractArray{Complex{T}}) = eps(float(maximum(x->(isfinite(x) ? abs(x) : T(NaN)), a)))
array_eps(a) = eps(float(maximum(x->(isfinite(x) ? abs(x) : oftype(x,NaN)), a)))

test_approx_eq(va, vb, astr, bstr) =
    test_approx_eq(va, vb, 1E4*length(va)*max(array_eps(va), array_eps(vb)), astr, bstr)

"""
    @test_approx_eq_eps(a, b, tol)

Test two floating point numbers `a` and `b` for equality taking in account a margin of tolerance given by `tol`.
"""
macro test_approx_eq_eps(a, b, c)
    :(test_approx_eq($(esc(a)), $(esc(b)), $(esc(c)), $(string(a)), $(string(b))))
end

"""
    @test_approx_eq(a, b)

Test two floating point numbers `a` and `b` for equality taking in account small numerical errors.
"""
macro test_approx_eq(a, b)
    :(test_approx_eq($(esc(a)), $(esc(b)), $(string(a)), $(string(b))))
end

macro inferred(ex)
    ex.head == :call || error("@inferred requires a call expression")
    Base.remove_linenums!(quote
        vals = ($([esc(ex.args[i]) for i = 2:length(ex.args)]...),)
        inftypes = Base.return_types($(esc(ex.args[1])), Base.typesof(vals...))
        @assert length(inftypes) == 1
        result = $(esc(ex.args[1]))(vals...)
        rettype = isa(result, Type) ? Type{result} : typeof(result)
        rettype == inftypes[1] || error("return type $rettype does not match inferred return type $(inftypes[1])")
        result
    end)
end

# Test approximate equality of vectors or columns of matrices modulo floating
# point roundoff and phase (sign) differences.
#
# This function is design to test for equality between vectors of floating point
# numbers when the vectors are defined only up to a global phase or sign, such as
# normalized eigenvectors or singular vectors. The global phase is usually
# defined consistently, but may occasionally change due to small differences in
# floating point rounding noise or rounding modes, or through the use of
# different conventions in different algorithms. As a result, most tests checking
# such vectors have to detect and discard such overall phase differences.
#
# Inputs:
#     a, b:: StridedVecOrMat to be compared
#     err :: Default: m^3*(eps(S)+eps(T)), where m is the number of rows
#
# Raises an error if any columnwise vector norm exceeds err. Otherwise, returns
# nothing.
function test_approx_eq_modphase{S<:Real,T<:Real}(
        a::StridedVecOrMat{S}, b::StridedVecOrMat{T}, err=nothing)

    m, n = size(a)
    @test n==size(b, 2) && m==size(b, 1)
    err === nothing && (err=m^3*(eps(S)+eps(T)))
    for i=1:n
        v1, v2 = a[:, i], b[:, i]
        @test_approx_eq_eps min(abs(norm(v1-v2)), abs(norm(v1+v2))) 0.0 err
    end
end

