module VirtualMonkey
  class MysqlRunner
    include VirtualMonkey::DeploymentRunner
    include VirtualMonkey::EBS
    include VirtualMonkey::Mysql
    attr_accessor :scripts_to_run
    attr_accessor :db_ebs_prefix

    def run_promotion_operations
      config_master_from_scratch(s_one)
      s_one.relaunch
      s_one.dns_name = nil
      wait_for_snapshots
# need to wait for ebs snapshot, otherwise this could easily fail
      restore_server(s_two)
      s_one.wait_for_operational_with_dns
      wait_for_snapshots
      slave_init_server(s_one)
      promote_server(s_one)
    end

    def run_reboot_operations
      reboot_all(true) # serially_reboot = true
      wait_for_all("operational")
      # This sleep is for waiting for the slave to catch up to the master since they both reboot at once
      # This sleep does more than that. It waits for the master to be fully up.
      sleep 120
      run_reboot_checks
    end

    # This is where we perform multiple checks on the deployment after a reboot.
    def run_reboot_checks
      # one simple check we can do is the backup.  Backup can fail if anything is amiss
      @servers.each do |server|
        run_script("backup", server)
      end
    end


    # lookup all the RightScripts that we will want to run
    def lookup_scripts
     @scripts_mysql = [
                         [ 'restore', 'restore and become' ],
                         [ 'slave_init', 'slave init' ],
                         [ 'promote', 'EBS promote to master' ],
                         [ 'backup', 'EBS backup' ],
                         [ 'terminate', 'TERMINATE SERVER' ]
                       ]
      st = ServerTemplate.find(s_two.server_template_href)
      @scripts_to_run = {}
      @scripts_mysql.each { |a|
        @scripts_to_run[ a[0] ] = st.executables.detect { |ex| ex.name =~ /#{a[1]}/ }
        raise "FATAL: Script #{a[1]} not found" unless @scripts_to_run[ a[0] ]
      }

#      @scripts_to_run['restore'] = st.executables.detect { |ex| ex.name =~  /restore and become/i }
#      @scripts_to_run['slave_init'] = st.executables.detect { |ex| ex.name =~ /slave init v2/ }
#      @scripts_to_run['promote'] = st.executables.detect { |ex| ex.name =~ /promote to master/ }
#      @scripts_to_run['backup'] = st.executables.detect { |ex| ex.name =~ /EBS backup/ }
#      @scripts_to_run['terminate'] = st.executables.detect { |ex| ex.name =~ /TERMINATE/ }
      # hardwired script! (this is an 'anyscript' that users typically use to setup the master dns)
      @scripts_to_run['master_init'] = RightScript.new('href' => "/api/acct/2901/right_scripts/195053")
      @scripts_to_run['create_stripe'] = RightScript.new('href' => "/api/acct/2901/right_scripts/198381")
      @scripts_to_run['create_mysql_ebs_stripe'] = RightScript.new('href' => "/api/acct/2901/right_scripts/212492")
      tbx = ServerTemplate.find_by(:nickname) { |n| n =~ /MySQL EBS Toolbox v2/ }
      # Use the HEAD revision.
      @scripts_to_run['create_migrate_script'] = tbx[0].executables.detect { |ex| ex.name =~ /DB EBS create migrate script from MySQL EBS v1 master/ }
     raise "FATAL: Need 2 MySQL servers in the deployment" unless @servers.size == 2
    end

    def migrate_slave
      s_one.settings
      s_one.spot_check_command("/tmp/init_slave.sh")
      eun_script("backup", s_one)
    end
   
    def launch_v2_slave
      s_two.settings
      wait_for_snapshots
      run_script("slave_init",s_two)
    end

    def run_restore_with_timestamp_override
      s_one.relaunch
      s_one.dns_name = nil
      s_one.wait_for_operational_with_dns
      audit = s_one.run_executable(@scripts_to_run['restore'], { "OPT_DB_RESTORE_TIMESTAMP_OVERRIDE" => "text:#{find_snapshot_timestamp}" } )
      audit.wait_for_completed
    end
  end
end
