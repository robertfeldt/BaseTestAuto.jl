""" 
Traverse an Expr and call a `fn` on each sub-expression while accumulating
results.
"""
function traverse_expr(expr::Expr, fn = (ex,a) -> (ex, a), accumulator = Any[]; 
  update = false, # true iff we should insert the ex returned from the fn while traversing
  inclOrigExpr = false # true iff we should call the fn with a 3rd argument being the orig expr
  )

  if inclOrigExpr
    orig_expr = expr
    if update
      expr = deepcopy(orig_expr) # Must deepcopy here since it might otherwise change before we call fn
    end
  end

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
    nsub, accumulator = traverse_expr(expr.args[i], fn, accumulator; 
      update = update, inclOrigExpr = inclOrigExpr)
    if update
      expr.args[i] = nsub
    end
  end

  # Now call the fn on this expr we are in
  if inclOrigExpr
    nexpr, accumulator = fn(expr, accumulator, orig_expr)
  else
    nexpr, accumulator = fn(expr, accumulator)
  end

  if update
    expr = nexpr
  end

  return expr, accumulator
end

function traverse_expr(expr, fn = (ex,a) -> (ex, a), accumulator = Any[]; 
  update = false,
  inclOrigExpr = false)
  inclOrigExpr ? fn(expr, accumulator, expr) : fn(expr, accumulator)
end

# Maybe we should instead define an iterator and just reuse existing filter et al?
function filter(selectfn::Function, expr::Expr)
  visitorfn(ex, acc) = (selectfn(ex) == true) ? (ex, push!(acc, ex)) : (ex, acc)
  ex, acc = traverse_expr(expr, visitorfn)
  acc
end
