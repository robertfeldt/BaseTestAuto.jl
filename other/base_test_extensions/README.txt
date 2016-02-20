Here we save extenstions of the base/test.jl originals. This is just so we can more
easily mix-and-match different fixes and extensions to base/test.jl that might
be rejected or take some time to get accepted/rejected into/from julia's main git.
We number them based on the original base/test.jl version from the 
other/base_test_originals dir.

Descriptions of extensions

* base_test_0_0_should_run_method_on_AbstractTestSet.jl
  - PR: https://github.com/JuliaLang/julia/pull/15148
  - cd ~/dev/clones/julia; git checkout rf/scoping_in_testset; git show 8158a83a5c1ae78b37a33b5df8d7d713aeb4b539:base/test.jl > temp.jl; mv temp.jl ~/dev/BaseTestAuto.jl/other/base_test_extensions/base_test_0_0_should_run_method_on_AbstractTestSet.jl

* 