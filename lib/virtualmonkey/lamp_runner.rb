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

    # These are mysql specific checks
    def run_checks
      # check that mysql tmpdir is custom setup on all servers
      query = "show variables like 'tmpdir'"
      query_command = "echo -e \"#{query}\"| mysql"
      @servers.each do |server|
        server.spot_check(query_command) { |result| raise "Failure: tmpdir was unset#{result}" unless result.include?("/mnt/mysqltmp") }
      end
    end

    # check that mysql can handle 5000 concurrent connections (file limits, etc.)
    def run_mysqlslap_check
      @servers.each do |server|
        result = server.spot_check_command("mysqlslap  --concurrency=5000 --iterations=10 --number-int-cols=2 --number-char-cols=3 --auto-generate-sql --csv=/tmp/mysqlslap_q1000_innodb.csv --engine=innodb --auto-generate-sql-add-autoincrement --auto-generate-sql-load-type=mixed --number-of-queries=1000 --user=root")
        raise "FATAL: mysqlslap check failed" unless result[:output].empty?
      end
    end

    # check that ulimit has been set correctly
    def ulimit_check
      @servers.each do |server|
        result = server.spot_check_command("su -s /bin/bash -c \"ulimit -n\" mysql")
        raise "FATAL: ulimit wasn't set correctly" unless result[:output].to_i > 1024
      end
    end

  end
end
