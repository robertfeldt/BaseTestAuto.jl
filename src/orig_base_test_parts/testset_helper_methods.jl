# Various helper methods for test sets

"""
    get_testset()

Retrieve the active test set from the task's local storage. If no
test set is active, use the fallback default test set.
"""
function get_testset()
    testsets = get(task_local_storage(), :__BASETESTNEXT__, AbstractTestSet[])
    return isempty(testsets) ? fallback_testset : testsets[end]
end

"""
    push_testset(ts::AbstractTestSet)

Adds the test set to the task_local_storage.
"""
function push_testset(ts::AbstractTestSet)
    testsets = get(task_local_storage(), :__BASETESTNEXT__, AbstractTestSet[])
    push!(testsets, ts)
    setindex!(task_local_storage(), testsets, :__BASETESTNEXT__)
end

"""
    pop_testset()

Pops the last test set added to the task_local_storage. If there are no
active test sets, returns the fallback default test set.
"""
function pop_testset()
    testsets = get(task_local_storage(), :__BASETESTNEXT__, AbstractTestSet[])
    ret = isempty(testsets) ? fallback_testset : pop!(testsets)
    setindex!(task_local_storage(), testsets, :__BASETESTNEXT__)
    return ret
end

"""
    get_testset_depth()

Returns the number of active test sets, not including the defaut test set
"""
function get_testset_depth()
    testsets = get(task_local_storage(), :__BASETESTNEXT__, AbstractTestSet[])
    return length(testsets)
end

