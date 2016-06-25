# We only use BaseTestNext functionality when testing BaseTestAuto
# rather than testing BaseTestAuto with itself...
if VERSION >= v"0.5-"
    using Base.Test
else
    using BaseTestNext
    const Test = BaseTestNext
end

# walkdir function copied from julia 0.5 repo. Not yet in 0.4
function walkdir(root; topdown=true, follow_symlinks=false, onerror=throw)
    content = nothing
    try
        content = readdir(root)
    catch err
        isa(err, SystemError) || throw(err)
        onerror(err)
        #Need to return an empty task to skip the current root folder
        return Task(()->())
    end
    dirs = Array(eltype(content), 0)
    files = Array(eltype(content), 0)
    for name in content
        if isdir(joinpath(root, name))
            push!(dirs, name)
        else
            push!(files, name)
        end
    end

    function _it()
        if topdown
            produce(root, dirs, files)
        end
        for dir in dirs
            path = joinpath(root,dir)
            if follow_symlinks || !islink(path)
                for (root_l, dirs_l, files_l) in walkdir(path, topdown=topdown, follow_symlinks=follow_symlinks, onerror=onerror)
                    produce(root_l, dirs_l, files_l)
                end
            end
        end
        if !topdown
            produce(root, dirs, files)
        end
    end
    Task(_it)
end

function runtestsindir(dir, testFileRegex = r"^test_.*\.jl$")
  for (root, dirs, files) in walkdir(dir)
    # Run tests in this dir that matches `testFileRegex`
    for file in files
      if ismatch(testFileRegex, file)
        include(joinpath(root, file))
      end
    end
    # Traverse into subdirs and runs there
    for dir in dirs
      runtestsindir(dir, testFileRegex)
    end
  end
end

TestDir = dirname(@__FILE__())

include(joinpath(TestDir, "helper.jl"))

@testset "BaseTestAuto test suite" begin
  include(joinpath(TestDir, "test_test_assertion.jl"))
  include(joinpath(TestDir, "test_predicate_true_assertion.jl"))
  include(joinpath(TestDir, "test_exception_thrown_assertion.jl"))
  include(joinpath(TestDir, "test_accumulator_assertion.jl"))
  include(joinpath(TestDir, "test_common_multi_values_assertions.jl"))

  include(joinpath(TestDir, "test_traverse_expression.jl"))
  include(joinpath(TestDir, "test_stepwise_expr_evaluation.jl"))

  include(joinpath(TestDir, "test_test_macro.jl"))
end