# We want to evaluate the sub expressions of an expression separately
# so that we can give more detailed information on where the fault is 
# likely to be located. We also need to show the values of each variable
# reference in the expression, so evaluate them separately too.
#
# toplevelvar, subexprs, evaledexpr = split_in_subexpressions(expr)

"""
Find the variable references and function calls in expr and create a
sequence of sub-expressions that, when evaluated, trace the same evaluation
and evaluates to the same value as expr. Variables will be escaped in
the trace while function calls are kept as is.
"""
function split_in_subexpressions(expr)
  # Find var refs and calls. The former are escaped in the substituting expr.
  # The context is array of tuples: (origexpr, tempvarname, newexpr). We traverse
  traverse_expr(expr, acc_vars_and_calls_and_insert_tempvars; update = true, inclOrigExpr = true)
end

# Accumulate variables and calls while substituting them for temp var names.
function acc_vars_and_calls_and_insert_tempvars(s::Symbol, acc, origex)
    tvar = subst_expr!(acc, s, gensym(), esc(s)) # Escape symbols
    (tvar, acc)
end
function acc_vars_and_calls_and_insert_tempvars(e::Expr, acc, origex)
    if e.head == :call
        tvar = subst_expr!(acc, origex, gensym(), e) # Don't escape func calls
        (tvar, acc)
    else
        (e, acc)
    end
end
acc_vars_and_calls_and_insert_tempvars(e, acc, origex) = (e, acc) # For literals and other node types: do nothing

#function split_in_intermediate_exprs(expr::Expr, maxnesting = 2)
#  intermediate_assignments = Any[] # Tuples in format (origexpr, lhsvarname, rhsexpr)
#  topexpr = split_in_intermediate_exprs!(deepcopy(expr), intermediate_assignments, maxnesting)
#  # Ensure we at least put the top expression as a sub expression
#  if length(intermediate_assignments) == 0
#    push!(intermediate_assignments, (deepcopy(expr), gensym(), expr))
#    topexpr = intermediate_assignments[end][2]
#  end
#  return (topexpr, intermediate_assignments)
#end

is_nonoperator_funcname(fname) = match(r"^[a-zA-Z]", string(fname)) != nothing

# Add result tuple unless expr already in context, then return temp var
# to represent the expr.
function subst_expr!(context, orig_ex, tempvar, ex)
  idx = findfirst(t -> t[1] == orig_ex, context)
  if idx > 0
    return context[idx][2]
  else
    push!(context, (orig_ex, tempvar, ex))
    return tempvar
  end
end

# Traverses Expr trees while accumulating expressions for intermediate values.
#function split_in_intermediate_exprs!(expr, result, maxnesting)
#  orig_expr = deepcopy(expr) # since we will update the orig one below
#  if isa(expr, Symbol)
#    return subst_expr!(result, orig_expr, gensym("temp"), esc(expr))
#  elseif isa(expr, Expr)
#    if expr.head == :comparison
#      for i in 1:2:length(expr.args)
#        expr.args[i] = split_in_intermediate_exprs!(expr.args[i], result, maxnesting)
#      end
#      push!(result, (orig_expr, gensym("temp"), expr))
#      return result[end][2]
#    elseif expr.head == :call
#      # Look for vars in args from 2 and on since arg 1 is the function name
#      for i in 2:length(expr.args)
#        expr.args[i] = split_in_intermediate_exprs!(expr.args[i], result, maxnesting-1)
#      end
#      if maxnesting > 0 && is_nonoperator_funcname(expr.args[1]) # include this func call?
#        push!(result, (orig_expr, gensym("temp"), expr))
#        return result[end][2]
#      else
#        return expr
#      end
#    elseif expr.head == :ref
#      # Look for vars in args from 2 and on since arg 1 is the function name
#      for i in 2:length(expr.args)
#        expr.args[i] = split_in_intermediate_exprs!(expr.args[i], result, maxnesting-1)
#      end
#      push!(result, (orig_expr, gensym("temp"), expr))
#      return result[end][2]
#    end
#  end
#  return expr # For all other types we return them untouched.
#end
#
#"""
#Split `expr` so we can save intermediate results of its var refs, comparisons, and
#func calls (in temp vars). Returns the transformed `expr` and a list of tuples
#for each intermediate variable, its RHS expr and the original expr it corresponds to.
#"""
#function split_in_intermediate_exprs(expr::Expr, maxnesting = 2)
#  intermediate_assignments = Any[] # Tuples in format (origexpr, lhsvarname, rhsexpr)
#  topexpr = split_in_intermediate_exprs!(deepcopy(expr), intermediate_assignments, maxnesting)
#  # Ensure we at least put the top expression as a sub expression
#  if length(intermediate_assignments) == 0
#    push!(intermediate_assignments, (deepcopy(expr), gensym(), expr))
#    topexpr = intermediate_assignments[end][2]
#  end
#  return (topexpr, intermediate_assignments)
#end
# Special handling of constants like Int64, Symbol etc
#function split_in_intermediate_exprs(x, maxnesting = 2)
#  tvar = gensym()
#  (:($tvar), Any[(x, tvar, x)])
#end

q(x::Int64) = Expr(:quote, x)
q(s::Symbol) = Expr(:quote, s)
function q(ex::Expr)
  ex.head == :quote ? ex : Expr(:quote, ex)
end

function tempvarblock(orig_ex, orig_subexpr, tempvarname, subexpr, contextarray)
    ose = Expr(:quote, orig_subexpr)
    :(  
      if res == nothing
        try
            $tempvarname = $(subexpr)
            push!($contextarray, ($ose, $tempvarname))
        catch _e
            res = Threw($orig_ex, $ose, _e, $contextarray)
        end
      end
    )
end

"""
  Assemble a value and context block Expr that saves the key sub expressions in `expr` 
  and their values in an array. Each sub expression is evaluated in its own 
  try/catch block so we can pinpoint which one failed, if any.
"""
function build_stepwise_value_context_expr(expr::Expr)
  orig_expr = q(expr)
  #toplevelvar, assignments = split_in_intermediate_exprs(expr)
  toplevelvar, assignments = split_in_subexpressions(expr)

  # Generate a temporary for every sub expression
  n = length(assignments)
  tempvars = map(t->t[2], assignments) # 2nd element is the tempvar name to assign to

  # Now create a block to evaluate expression in steps and return the trace.
  evalblock = Expr(:block)

  # First stmt of block declares all temp vars local
  evalblock.args = [Expr(:local, tempvars...)]

  # 2nd stmt of block declares result var local
  push!(evalblock.args, :(local res = nothing) )

  # 3rd stmt of block creates the context array which is initially empty
  contextarrayname = gensym("context")
  push!( evalblock.args, :(local $contextarray = Any[]) )

  # Add an assignment per sub expression, each one in a try/catch so we can
  # pinpoint where the expression was raised if there is one. 
  for i in 1:n
    orig_subexpr, tempvar, subexpr = assignments[i]
    push!(evalblock.args, 
        tempvarblock(orig_expr, orig_subexpr, tempvar, subexpr, contextarrayname))
    # Fail fast if there was an exception
    #push!(evalblock.args, 
    #    :( !isa(res, Void) || return(res) ))
  end

  # Assign a normal return value if no exceptions so far during eval of sub expressions.
  push!(evalblock.args, :(
    if res == nothing
      res = Returned($orig_expr, $toplevelvar, $contextarray)
    end
  ))
  # And last stmt of the block returns
  push!(evalblock.args, :(res))

  Base.remove_linenums!(evalblock)
  evalblock
end

# Very simple if the expression is a constant
function build_stepwise_value_context_expr(constantexpr)
  :(Returned($constantexpr, $constantexpr, Any[]))
end

#
# Helper methods to print context nicely and debug these functions.
#
#stringify_tuple(t) = map(string, t)
#
#function report_context(ct)
#    strs = map( stringify_tuple, reverse(ct))
#    maxwidth = maximum(map(t -> length(t[1]), strs[2:end]))
#    merget(t, maxw) = lpad(t[1], maxw) * "   # =>   " * t[2]
#    subexprs = map(t -> merget(t, maxwidth+1), strs[2:end])
#    toplevel = "Expression:      " * merget(strs[1], 0) * 
#             "\n  Subexpressions:\n    "
#    toplevel * join(subexprs, "\n    ")
#end
#
#function eval_and_report(expr)
#    evalexpr = build_stepwise_value_context_expr(expr)
#    r = eval(evalexpr)
#    # @show r
#    println(report_context(r.context))
#end
