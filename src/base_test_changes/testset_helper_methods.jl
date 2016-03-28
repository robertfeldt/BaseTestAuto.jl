# Various helper methods for test sets

const TESTSET_STACK_KEY = :__BASETESTNEXT__

function get_testset_stack()
    get(task_local_storage(), TESTSET_STACK_KEY, AbstractTestSet[])
end

function set_testset_stack(testsets)
    setindex!(task_local_storage(), testsets, TESTSET_STACK_KEY)
end

"""
    get_testset()

Retrieve the active test set from the task's local storage. If no
test set is active, use the fallback default test set.
"""
function get_testset()
    testsets = get_testset_stack()
    return isempty(testsets) ? fallback_testset : testsets[end]
end

"""
    push_testset(ts::AbstractTestSet)

Adds the test set to the task_local_storage.
"""
function push_testset(ts::AbstractTestSet)
    testsets = get_testset_stack()
    push!(testsets, ts)
    set_testset_stack(testsets)
end

"""
    pop_testset()

Pops the last test set added to the task_local_storage. If there are no
active test sets, returns the fallback default test set.
"""
function pop_testset()
    testsets = get_testset_stack()
    ret = isempty(testsets) ? fallback_testset : pop!(testsets)
    set_testset_stack(testsets)
    return ret
end

"""
    get_testset_depth()

Returns the number of active test sets, not including the default test set
"""
function get_testset_depth()
    testsets = get_testset_stack()
    return length(testsets)
end
