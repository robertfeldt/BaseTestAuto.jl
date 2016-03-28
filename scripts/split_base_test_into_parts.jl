# Split base/test.jl orig file into logically separated parts we can extend individually.
# The line numbers here are from my proposed base/test.jl extension PR
# https://github.com/JuliaLang/julia/pull/15148
Parts = [
  ( 23, 125, "test_result.jl"),
  (130, 216, "test_macro.jl"),
  (220, 252, "test_throws_macro.jl"),
  (256, 315, "abstract_testset.jl"),
  (319, 336, "fallback_testset.jl"),
  (340, 535, "default_testset.jl"),
  (539, 692, "testset_macros.jl"),
  (695, 740, "testset_helper_methods.jl"),
  (743, 842, "legacy_testing_methods.jl")
]

FromFileName = "other/base_test_extensions/base_test_0_0_should_run_method_on_AbstractTestSet.jl"
TargetDir = "src/orig_base_test_parts"
open(FromFileName, "r") do infh
  lines = readlines(infh)
  for (startline, endline, filename) in Parts
    targetfile = TargetDir * "/" * filename
    open(targetfile, "w") do outfh
      ls = lines[startline:endline]
      println("Printing $(length(ls)) lines to file $targetfile")
      println(outfh, join(ls))
    end
  end
end