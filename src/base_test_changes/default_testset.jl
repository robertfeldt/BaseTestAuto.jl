"""
    DefaultTestSet

If using the DefaultTestSet, the test results will be recorded. If there
are any `Fail`s or `Error`s, an exception will be thrown only at the end,
along with a summary of the test results.
"""
type DefaultTestSet <: AbstractTestSet
    description::AbstractString
    results::Vector
    anynonpass::Bool
    repeats::Int # number of repeated runs of the tests, defaults to 1
    skip::Bool   # true iff we should not run tests in this testset, defaults to false
end
DefaultTestSet(desc; repeats=1, skip=false) =
    DefaultTestSet(desc, [], false, repeats, skip)

# For a passing result, simply store the result
record(ts::DefaultTestSet, t::Pass) = (push!(ts.results, t); t)
# For the other result types, immediately print the error message
# but do not terminate. Print a backtrace.
function record(ts::DefaultTestSet, t::Union{Fail,Error})
    print_with_color(:white, ts.description, ": ")
    print(t)
    # don't print the backtrace for Errors because it gets printed in the show
    # method
    isa(t, Error) || Base.show_backtrace(STDOUT, backtrace())
    println()
    push!(ts.results, t)
    t
end

# When a DefaultTestSet finishes, it records itself to its parent
# testset, if there is one. This allows for recursive printing of
# the results at the end of the tests
record(ts::DefaultTestSet, t::AbstractTestSet) = push!(ts.results, t)

# If we shouldn't skip this testset and if we have not yet executed the tests
# the required number of times (default is 1) we should run again.
function should_run(ts::DefaultTestSet, nruns::Int)
    (ts.skip == false) && (nruns < ts.repeats)
end

# Called at the end of a @testset, behaviour depends on whether
# this is a child of another testset, or the "root" testset
function finish(ts::DefaultTestSet)
    # If we are a nested test set, do not print a full summary
    # now - let the parent test set do the printing
    if get_testset_depth() != 0
        # Attach this test set to the parent test set
        parent_ts = get_testset()
        record(parent_ts, ts)
        return
    end
    # Calculate the overall number for each type so each of
    # the test result types are aligned
    passes, fails, errors, c_passes, c_fails, c_errors = get_test_counts(ts)
    total_pass  = passes + c_passes
    total_fail  = fails  + c_fails
    total_error = errors + c_errors
    dig_pass  = total_pass  > 0 ? ndigits(total_pass) : 0
    dig_fail  = total_fail  > 0 ? ndigits(total_fail)  : 0
    dig_error = total_error > 0 ? ndigits(total_error) : 0
    total = total_pass + total_fail + total_error
    dig_total = total > 0 ? ndigits(total) : 0
    # For each category, take max of digits and header width if there are
    # tests of that type
    pass_width  = dig_pass  > 0 ? max(length("Pass"),  dig_pass)  : 0
    fail_width  = dig_fail  > 0 ? max(length("Fail"),  dig_fail)  : 0
    error_width = dig_error > 0 ? max(length("Error"), dig_error) : 0
    total_width = dig_total > 0 ? max(length("Total"), dig_total) : 0
    # Calculate the alignment of the test result counts by
    # recursively walking the tree of test sets
    align = max(get_alignment(ts, 0), length("Test Summary:"))
    # Print the outer test set header once
    print_with_color(:white, rpad("Test Summary:",align," "))
    print(" | ")
    if pass_width > 0
        print_with_color(:green, lpad("Pass",pass_width," "))
        print("  ")
    end
    if fail_width > 0
        print_with_color(:red, lpad("Fail",fail_width," "))
        print("  ")
    end
    if error_width > 0
        print_with_color(:red, lpad("Error",error_width," "))
        print("  ")
    end
    if total_width > 0
        print_with_color(:blue, lpad("Total",total_width," "))
    end
    println()
    # Recursively print a summary at every level
    print_counts(ts, 0, align, pass_width, fail_width, error_width, total_width)
    # Finally throw an error as we are the outermost test set
    if total != total_pass
        throw(TestSetException(total_pass,total_fail,total_error))
    end

    # return the testset so it is returned from the @testset macro
    ts
end

# Recursive function that finds the column that the result counts
# can begin at by taking into account the width of the descriptions
# and the amount of indentation. If a test set had no failures, and
# no failures in child test sets, there is no need to include those
# in calculating the alignment
function get_alignment(ts::DefaultTestSet, depth::Int)
    # The minimum width at this depth is...
    ts_width = 2*depth + length(ts.description)
    # If all passing, no need to look at children
    !ts.anynonpass && return ts_width
    # Return the maximum of this width and the minimum width
    # for all children (if they exist)
    isempty(ts.results) && return ts_width
    child_widths = map(t->get_alignment(t, depth+1), ts.results)
    return max(ts_width, maximum(child_widths))
end
get_alignment(ts, depth::Int) = 0

# Recursive function that counts the number of test results of each
# type directly in the testset, and totals across the child testsets
function get_test_counts(ts::DefaultTestSet)
    passes, fails, errors = 0, 0, 0
    c_passes, c_fails, c_errors = 0, 0, 0
    for t in ts.results
        isa(t, Pass)  && (passes += 1)
        isa(t, Fail)  && (fails  += 1)
        isa(t, Error) && (errors += 1)
        if isa(t, DefaultTestSet)
            np, nf, ne, ncp, ncf, nce = get_test_counts(t)
            c_passes += np + ncp
            c_fails  += nf + ncf
            c_errors += ne + nce
        end
    end
    ts.anynonpass = (fails + errors + c_fails + c_errors > 0)
    return passes, fails, errors, c_passes, c_fails, c_errors
end

# Recursive function that prints out the results at each level of
# the tree of test sets
function print_counts(ts::DefaultTestSet, depth, align,
                        pass_width, fail_width, error_width, total_width)
    # Count results by each type at this level, and recursively
    # through and child test sets
    passes, fails, errors, c_passes, c_fails, c_errors = get_test_counts(ts)
    subtotal = passes + fails + errors + c_passes + c_fails + c_errors

    # Print test set header, with an alignment that ensures all
    # the test results appear above each other
    print(rpad(string("  "^depth, ts.description), align, " "), " | ")

    np = passes + c_passes
    if np > 0
        print_with_color(:green, lpad(string(np), pass_width, " "), "  ")
    elseif pass_width > 0
        # No passes at this level, but some at another level
        print(" "^pass_width, "  ")
    end

    nf = fails + c_fails
    if nf > 0
        print_with_color(:red, lpad(string(nf), fail_width, " "), "  ")
    elseif fail_width > 0
        # No fails at this level, but some at another level
        print(" "^fail_width, "  ")
    end

    ne = errors + c_errors
    if ne > 0
        print_with_color(:red, lpad(string(ne), error_width, " "), "  ")
    elseif error_width > 0
        # No errors at this level, but some at another level
        print(" "^error_width, "  ")
    end

    if np == 0 && nf == 0 && ne == 0
        if ts.skip
            print_with_color(:yellow, "Skipped")
        else
            print_with_color(:blue, "No tests")
        end
    else
        print_with_color(:blue, lpad(string(subtotal), total_width, " "))
    end
    println()

    # Only print results at lower levels if we had failures
    if np != subtotal
        for t in ts.results
            if isa(t, DefaultTestSet)
                print_counts(t, depth + 1, align,
                                pass_width, fail_width, error_width, total_width)
            end
        end
    end
end

