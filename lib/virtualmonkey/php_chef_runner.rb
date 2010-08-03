module VirtualMonkey
  class PhpChefRunner
    include VirtualMonkey::DeploymentRunner
    include VirtualMonkey::ApplicationFrontend
  end
end
