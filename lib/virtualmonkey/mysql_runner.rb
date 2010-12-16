module VirtualMonkey
  class MysqlRunner
    include VirtualMonkey::DeploymentRunner
    include VirtualMonkey::EBS
    include VirtualMonkey::Mysql
    attr_accessor :scripts_to_run
    attr_accessor :db_ebs_prefix

    # It's not that I'm a Java fundamentalist; I merely believe that mortals should
    # not be calling the following methods directly. Instead, they should use the
    # TestCaseInterface methods (behavior, verify, probe) to access these functions.
    # Trust me, I know what's good for you. -- Tim R.
    private

    def run_promotion_operations
      behavior(:config_master_from_scratch, s_one)
      object_behavior(s_one, :relaunch)
      s_one.dns_name = nil
      behavior(:wait_for_snapshots)
# need to wait for ebs snapshot, otherwise this could easily fail
      behavior(:restore_server, s_two)
      object_behavior(s_one, :wait_for_operational_with_dns)
      behavior(:wait_for_snapshots)
      behavior(:slave_init_server, s_one)
      behavior(:promote_server, s_one)
    end

    def run_reboot_operations
# Duplicate code here because we need to wait between the master and the slave time
      #reboot_all(true) # serially_reboot = true
      @servers.each do |s|
        object_behavior(s, :reboot, true)
        object_behavior(s, :wait_for_state, "operational")
# TODO put a check in here to see if mysql is fully up before rebooting the next server
# The slave was rebooting to soon after the master came up.
        sleep 600
      end
      behavior(:wait_for_all, "operational")
      behavior(:run_reboot_checks)
    end

    # This is where we perform multiple checks on the deployment after a reboot.
    def run_reboot_checks
      # one simple check we can do is the backup.  Backup can fail if anything is amiss
      @servers.each do |server|
        behavior(:run_script, "backup", server)
      end
    end


    # lookup all the RightScripts that we will want to run
    def lookup_scripts
#TODO fix this so epoch is not hard coded.
puts "WE ARE HARDCODING THE TOOL BOX NAMES TO USE 11H1.b1"
     scripts = [
                 [ 'restore', 'restore and become' ],
                 [ 'slave_init', 'slave init' ],
                 [ 'promote', 'EBS promote to master' ],
                 [ 'backup', 'EBS backup' ],
                 [ 'terminate', 'TERMINATE SERVER' ]
               ]
      ebs_toolbox_scripts = [
                              [ 'create_stripe' , 'EBS stripe volume create - 11H1.b1' ]
                            ]
      mysql_toolbox_scripts = [
                              [ 'create_mysql_ebs_stripe' , 'DB Create MySQL EBS stripe volume - 11H1.b1' ],
                              [ 'create_migrate_script' , 'DB EBS create migrate script from MySQL EBS v1' ]
                            ]
      st = ServerTemplate.find(s_two.server_template_href)
      lookup_scripts_table(st,scripts)
      @scripts_to_run['master_init'] = RightScript.new('href' => "/api/acct/2901/right_scripts/195053")
      #This does not work - does not create the same type as call above does.
      #@scripts_to_run['master_init'] = RightScript.find_by("name") { |n| n =~ /DB register master \-ONLY FOR TESTING/ }
      raise "Did not find script" unless @scripts_to_run['master_init']

      tbx = ServerTemplate.find_by(:nickname) { |n| n =~ /EBS Stripe Toolbox - 11H1.b1/ }
      raise "Did not find toolbox template" unless tbx[0]
      # Use the HEAD revision.
      lookup_scripts_table(tbx[0],ebs_toolbox_scripts)
#      @scripts_to_run['create_stripe'] = RightScript.new('href' => "/api/acct/2901/right_scripts/198381")
#TODO - does not account for 5.0/5.1 toolbox differences
puts "USING MySQL 5.0 toolbox"
      tbx = ServerTemplate.find_by(:nickname) { |n| n =~ /Database Manager with MySQL 5.0 Toolbox - 11H1.b1/ }
      raise "Did not find toolbox template" unless tbx[0]
      lookup_scripts_table(tbx[0],mysql_toolbox_scripts)
#      @scripts_to_run['create_mysql_ebs_stripe'] = RightScript.new('href' => "/api/acct/2901/right_scripts/212492")
#      @scripts_to_run['create_migrate_script'] = tbx[0].executables.detect { |ex| ex.name =~ /DB EBS create migrate script from MySQL EBS v1 master/ }
     raise "FATAL: Need 2 MySQL servers in the deployment" unless @servers.size == 2
    end

    def migrate_slave
      s_one.settings
      object_behavior(s_one, :spot_check_command, "/tmp/init_slave.sh")
      behavior(:run_script, "backup", s_one)
    end
   
    def launch_v2_slave
      s_two.settings
      behavior(:wait_for_snapshots)
      behavior(:run_script, "slave_init", s_two)
    end

    def run_restore_with_timestamp_override
      object_behavior(s_one, :relaunch)
      s_one.dns_name = nil
      s_one.wait_for_operational_with_dns
      audit = object_behavior(s_one, :run_executable, @scripts_to_run['restore'], { "OPT_DB_RESTORE_TIMESTAMP_OVERRIDE" => "text:#{find_snapshot_timestamp}" } )
      audit.wait_for_completed
    end
  end
end
