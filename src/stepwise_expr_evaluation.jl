is_nonoperator_funcname(fname) = match(r"^[a-zA-Z]", string(fname)) != nothing

# Traverses Expr trees while accumulating expressions for intermediate values.
function split_in_intermediate_exprs!(expr, result, maxnesting)
  orig_expr = deepcopy(expr) # since we will update the orig one below
  if isa(expr, Symbol)
    push!(result, (orig_expr, gensym("temp"), esc(expr)))
    return result[end][2]
  elseif isa(expr, Expr)
    if expr.head == :comparison
      for i in 1:2:length(expr.args)
        expr.args[i] = split_in_intermediate_exprs!(expr.args[i], result, maxnesting)
      end
      push!(result, (orig_expr, gensym("temp"), expr))
      return result[end][2]
    elseif expr.head == :call
      # Look for vars in args from 2 and on since arg 1 is the function name
      for i in 2:length(expr.args)
        expr.args[i] = split_in_intermediate_exprs!(expr.args[i], result, maxnesting-1)
      end
      if maxnesting > 0 && is_nonoperator_funcname(expr.args[1]) # include this func call?
        push!(result, (orig_expr, gensym("temp"), expr))
        return result[end][2]
      else
        return expr
      end
    end
  end
  return expr # For all other types we return them untouched.
end

"""
Split `expr` so we can save intermediate results of its var refs, comparisons, and
func calls (in temp vars). Returns the transformed `expr` and a list of tuples
for each intermediate variable, its RHS expr and the original expr it corresponds to.
"""
function split_in_intermediate_exprs(expr, maxnesting = 2)
  intermediate_assignments = Any[] # Tuples in format (origexpr, lhsvarname, rhsexpr)
  topexpr = split_in_intermediate_exprs!(deepcopy(expr), intermediate_assignments, maxnesting)
  return (topexpr, intermediate_assignments)
end

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
  toplevelvar, assignments = split_in_intermediate_exprs(expr)

  # Generate a temporary for every sub expression
  n = length(assignments)
  tempvars = map(t->t[2], assignments) # 2nd element is the tempvar name to assign to

  # Now create a block to evaluate expression in steps and return the trace.
  evalblock = Expr(:block)

  # First stmt of block declares all temp vars local
  evalblock.args = [Expr(:local, tempvars...)]

  # 2nd stmt of block declares result var local
  push!(evalblock.args, :(local res = nothing) )

  # Second stmt of block creates the context array
  contextarray = gensym("context")
  push!(evalblock.args, :(local $contextarray = Any[]) )

  # Add an assignment per sub expression, each one in a try/catch so we can
  # pinpoint where the expression was raised if there is one. 
  for i in 1:n
    orig_subexpr, tempvar, subexpr = assignments[i]
    push!(evalblock.args, 
        tempvarblock(orig_expr, orig_subexpr, tempvar, subexpr, contextarray))
    # Fail fast if there was an exception
    #push!(evalblock.args, 
    #    :( !isa(res, Void) || return(res) ))
  end

  # Last line of context block returns normally
  push!(evalblock.args, :(
    if res == nothing
      res = Returned($orig_expr, $toplevelvar, $contextarray)
    end
  ))
  push!(evalblock.args, :(res))

  Base.remove_linenums!(evalblock)
  evalblock
end

#
# Helper methods to print context nicely
#
stringify_tuple(t) = map(string, t)

function report_context(ct)
    strs = map( stringify_tuple, reverse(ct))
    maxwidth = maximum(map(t -> length(t[1]), strs[2:end]))
    merget(t, maxw) = lpad(t[1], maxw) * "   # =>   " * t[2]
    subexprs = map(t -> merget(t, maxwidth+1), strs[2:end])
    toplevel = "Expression:      " * merget(strs[1], 0) * 
             "\n  Subexpressions:\n    "
    toplevel * join(subexprs, "\n    ")
end

function eval_and_report(expr)
    evalexpr = build_stepwise_value_context_expr(expr)
    r = eval(evalexpr)
    @show r
    println(report_context(r.context))
end

macro tm(ex)
  tex = build_stepwise_value_context_expr(ex)
  @show tex
  quote
    begin
      $tex
    end
  end
end

a = 1
r1 = @tm a == 1
r2 = @tm a == 2
r3 = @tm b == 3
r4 = @tm a == c

