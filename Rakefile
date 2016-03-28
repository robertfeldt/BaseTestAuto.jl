Lib = "BaseTestAuto"
TestDir = "test"

# General parameters that the user can set from the command line.
Julia = ENV["minreps"] || "julia"
MinReps = (ENV["minreps"] || 30).to_i
MaxReps = (ENV["maxreps"] || 1000).to_i
MaxRepTime = (ENV["maxreptime"] || 1.0).to_f
Verbosity = ENV["verbosity"] || 2
MoreFactor = (ENV["morefactor"] || 10).to_i
MostFactor = (ENV["mostfactor"] || 1000).to_i
TimedTestMinFactor = (ENV["timedminfactor"] || 10).to_i
TimedTestMaxFactor = (ENV["timedmaxfactor"] || 1000).to_i

MainFile = "src/#{Lib}.jl"
BaseCommand = "#{Julia} --color=yes -L #{MainFile}"

task :origtest do
  sh "#{BaseCommand} test/orig_base_test_tests/test.jl"
end