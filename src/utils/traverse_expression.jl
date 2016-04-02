""" 
Traverse an Expr and call a `fn` on each sub-expression while accumulating
results.
"""
function traverse_expr(expr::Expr, fn = (ex,a) -> (ex, a), accumulator = Any[]; update = false)

  # If we are updating we do a (shallow) copy of the expr that we can then
  # update and return. This way the orig expr should not be affected.
  if update
    expr = copy(expr)
  end

  nargs = length(expr.args)

  # Find indices of sub expressions to traverse
  if in(expr.head, [:comparison])
    subidxs = 1:2:nargs
  elseif in(expr.head, [:call, :ref, :kw])
    subidxs = 2:1:nargs
  else
    subidxs = 1:nargs
  end

  # Depthfirst traversal, i.e. traverse first and then call on this expr
  for i in subidxs
    nsub, accumulator = traverse_expr(expr.args[i], fn, accumulator; update = update)
    if update
      expr.args[i] = nsub
    end
  end
  nexpr, accumulator = fn(expr, accumulator)
  if update
    expr = nexpr
  end

  return expr, accumulator
end

function traverse_expr(expr, fn = (ex,a) -> (ex, a), accumulator = Any[]; update = false)
  fn(expr, accumulator)
end

# Maybe we should instead define an iterator and just reuse existing filter et al?
function filter(selectfn::Function, expr::Expr)
  visitorfn(ex, acc) = (selectfn(ex) == true) ? (ex, push!(acc, ex)) : (ex, acc)
  ex, acc = traverse_expr(expr, visitorfn)
  acc
end
