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
BaseCommand = "time #{Julia} --color=yes -L #{MainFile}"

desc "Run orig base/test.jl tests"
task :origtest do
  sh "#{BaseCommand} test/orig_base_test_tests/test.jl"
end

desc "Run examples"
task :examples do
  sh "#{BaseCommand} examples/fixed_repeating_testset_example.jl"
end

desc "Test BaseTestAuto with Base.Test tests"
task :test do
  sh "#{BaseCommand} test/runtests.jl"
end

task :t do
  sh "julia --color=yes test/temptest.jl"
end

task :default => :test
