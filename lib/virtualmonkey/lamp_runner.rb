module VirtualMonkey
  class LampRunner
    include VirtualMonkey::DeploymentRunner
    include VirtualMonkey::UnifiedApplication

    def run_lamp_checks
      run_unified_application_checks(@servers, 80)
    end
  end
end
