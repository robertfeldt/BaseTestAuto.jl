# @test - check if the expression evaluates to true
# In the special case of a comparison, e.g. x == 5, generate code to
# evaluate each term in the comparison individually so the results
# can be displayed nicely.
"""
    @test ex
    @test ex AssertionCtor()
    @test ex AssertionCtor() option1=val1 option2=val2

Tests that the expression `ex` evaluates to `true`.
Returns a `Pass` `Result` if it does, a `Fail` `Result` if it is
`false`, and an `Error` `Result` if it could not be evaluated.
"""
macro test(args...)
    ex, orig_ex, assertionexpr, options = parse_test_macro_args(args)

    taid = gensym("ta")
    create_assertion_expr = quote
        get_asertion($(Expr(:quote, taid))) do
            ta = $(esc(assertionexpr))
            set_options(ta, $options)
            ta
        end
    end

    do_test_expr(create_assertion_expr, taid)
end

"""
Parse the arguments to the `@test` macro to pull out the expression to sample
(and assert), the expression to create the test assertion, and options.
"""
function parse_test_macro_args(args)
    ex = args[1] # First arg is the expression to be sampled

    # If 2nd arg is a call it is assumed to be the expression used to create the assertion
    if length(args) >= 2 && isa(args[2], Expr) && args[2].head == :call
        assertionexpr = args[2]
        nextarg = 3
    # If 2nd arg is just a symbol it is assumed to be the name of the TestAssertion type
    elseif length(args) >= 2 && isa(args[2], Symbol)
        assertionexpr = :($(args[2])())
        nextarg = 3
    else
        assertionexpr = :(PredicateTrueAssertion())
        nextarg = 2
    end

    # Any assignments are options
    options = :(Dict{Symbol, Any}())

    for arg in args[nextarg:end]
        # an assignment is an option
        if isa(arg, Expr) && arg.head == :(=)
            # we're building up a Dict literal here
            key = Expr(:quote, arg.args[1])
            push!(options.args, Expr(:(=>), key, arg.args[2]))
        else
            error("Unexpected argument $arg to @test")
        end
    end

    orig_ex = Expr(:quote, ex)
    (ex, orig_ex, assertionexpr, options)
end

isnonconst(s) = false
isnonconst(e::Expr) = true
isnonconst(s::Symbol) = true
isconst(e) = !isnonconst(e)
oneisconst(ex1, ex2) = (isconst(ex1) && isnonconst(ex2)) || (isnonconst(ex1) && isconst(ex2))

""" Is this a comparison of non constant expression to a constant expression? """
iscomparison_to_const(ex) = isa(ex, Expr) && (ex.head == :comparison) && 
    (ex.args[2] == :(==)) && oneisconst(ex.args[1], ex.args[3])

""" Split a comparison expression into its expr and const parts. """
function split_comparison_in_expr_and_const(ex::Expr)
    a1, op, a2 = ex.args
    if !isconst(a1)
        return (a1, op, a2)
    else
        return (a2, invert_op_direction(op), a1)
    end
end

const InvertedBinOpDirection = Dict{Symbol,Symbol}(
    :<  => :>,
    :<= => :>=,
    symbol("==") => symbol("=="),
    symbol("!=") => symbol("!="),
    :>  => :<,
    :>= => :<=
)
invert_op_direction(operator) = InvertedBinOpDirection[operator]

function do_test_expr(testassertion_ctor::Expr, taid::Symbol, evalresult::Expr)
    quoted_takey = Expr(:quote, gensym())
    quote
        $taid = get_testassertion($quoted_takey, () -> ($testassertion_ctor))
        if !isfulfilled($taid)
            ts = get_testset()
            if should_test(ts, $taid)
                local outcome
                res = $evalresult
                try
                    outcome = check($taid, res)
                catch _e2
                    outcome = AssertionCheckingError(_e2, $taid, res)
                end
                record(ts, outcome)
            end
        end
    end
end

function value_and_context_expr(orig_ex, ex, taid::Symbol)
    # TODO: Extend this to evaluate each sub-variable individually so we can pinpoint which part
    # of the expr leads to an exception, if any.
    # TODO: Should also handle function calls specially and save their values in the context, and not
    # only terms of a comparison.
    # TODO: Extend the code so it also collects non-func properties about the evaluation if the TestAssertion
    # saved in var taid requires it.

    # If the test is a comparison
    if isa(ex, Expr) && ex.head == :comparison
        # Generate a temporary for every term in the expression
        n = length(ex.args)
        terms = [gensym() for i in 1:n]
        # Create a new block that evaluates each term in the
        # comparison indivudally
        comp_block = Expr(:block)
        comp_block.args = [:(
                            $(terms[i]) = $(esc(ex.args[i]))
                            ) for i in 1:n]
        # The block should then evaluate whether the comparison
        # evaluates to true by splicing in the new terms into the
        # original comparsion. The block returns
        # - an expression with the values of terms spliced in
        # - the result of the comparison itself
        push!(comp_block.args,
              :(  Expr(:comparison, $(terms...)),  # Terms spliced in
                $(Expr(:comparison,   terms...)),  # Comparison itself
                  nonfunc_properties
                  ))
        testpair_expr = comp_block
    else
        testpair_expr = :(($orig_ex, $(esc(ex))))
    end

    quote
        if needs_nonfunc_properties($taid)
            starttime = time()
            value, context = $testpair_expr
            elapsed = time() - starttime
            value.metrics = Dict{Symbol,Any}(:elapsed => elapsed)
            return value, context
        else
            value, context = $testpair_expr
            value.metrics = Dict{Symbol,Any}()     # Empty non-func properties for now, ToFix 
            return value, context
        end
    end
end

function construct_testassertion_expr(origExpr, expr)
    expr
end