module VirtualMonkey
  class SimpleRunner
    include VirtualMonkey::DeploymentRunner
    include VirtualMonkey::Simple
  end
end
