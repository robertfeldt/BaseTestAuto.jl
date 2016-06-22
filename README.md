# BaseTestAuto.jl

An evolution of BaseTestNext.jl to support more automated forms of testing. Integrates a number of other testing-related packages to support random testing, parameterized unit testing, property-based testing etc.

We will gradually move code from our internal AutoTest.jl package (based in our software testing research) over to this package. The idea is to make as small changes as possible to the future Base.Test julia testing functionality while still adding value through automation. We target a first release in the summer of 2016.

For now you can look at our more complete (DataGenerators.jl)[http://github.com/simonpoulding/DataGenerators.jl] package for generating random test data as well as optimize that data for specific testing goals.