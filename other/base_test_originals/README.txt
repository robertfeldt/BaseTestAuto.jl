Here we save originals of the base/test.jl file since we will try to stay as closely
as possible to the functionality provided there. The core of BaseTestAuto.jl
should be fully compatible with the latest versions in here. We name/number them as:

  base_test_N.jl

where
 N is an int counting up from 0, with higher numbers indicating later versions.

Our proposed changes and extensions to a version saved as base_test_N.jl
are then named/numbered base_test_N_0.jl, base_test_N_1.jl etc.

We also list the commit version of each base_test_N.jl file below so that you can
extract them on your own using, for example:

cd ~/dev/clones/julia; git show 5d0be48c7fa30aa900b0e6dead666067611e1fdc:base/test.jl > base_test_0.jl; mv base_test_0.jl ~/dev/BaseTestAuto.jl/other/base_test_originals; cd ~/dev/BaseTestAuto.jl/other/base_test_originals

but obviously exchange my paths to the julia and BaseTestAuto.jl git repos to yours.

Filename,DateTime,JuliaMainRepoCommit
base_test_0.jl,20160207 12:27GMT,5d0be48c7fa30aa900b0e6dead666067611e1fdc
