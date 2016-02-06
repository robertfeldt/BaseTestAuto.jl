# We only use BaseTestNext functionality when testing BaseTestAuto
# rather than testing BaseTestAuto with itself...
if VERSION >= v"0.5-"
    using Base.Test
else
    using BaseTestNext
    const Test = BaseTestNext
end

function runtestsindir(dir, testFileRegex = r"^test_.*\.jl$")
  for (root, dirs, files) in walkdir(".")
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

@testset "Testing BaseTestAuto" begin
  runtestsindir(dirname(@__FILE__()))
end