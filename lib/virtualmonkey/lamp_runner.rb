module VirtualMonkey
  class LampRunner
    include VirtualMonkey::DeploymentRunner
    include VirtualMonkey::UnifiedApplication

    def run_lamp_checks
      # check that the standard unified app is responding on port 80
      run_unified_application_checks(@servers, 80)
      
      # TODO: check that running the mysql backup script succeeds
      # server.spot_check_command("/etc/cron.daily/mysql-dump-backup.sh")
      #
      # TODO: run operational RightScript(s)
      # 


      
    end
  end
end
