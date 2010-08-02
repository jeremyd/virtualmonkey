module VirtualMonkey
  class PhpAioTrialChefRunner
    include VirtualMonkey::DeploymentRunner
    include VirtualMonkey::ApplicationFrontend
  end
end
