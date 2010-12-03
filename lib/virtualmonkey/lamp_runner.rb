module VirtualMonkey
  class LampRunner
    include VirtualMonkey::DeploymentRunner
    include VirtualMonkey::UnifiedApplication
    include VirtualMonkey::Mysql

    # It's not that I'm a Java fundamentalist; I merely believe that mortals should
    # not be calling the following methods directly. Instead, they should use the
    # TestCaseInterface methods (behavior, verify, probe) to access these functions.
    # Trust me, I know what's good for you. -- Tim R.
    private

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
