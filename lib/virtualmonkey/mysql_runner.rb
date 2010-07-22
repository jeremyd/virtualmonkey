require 'ruby-debug'

module VirtualMonkey
  class MysqlRunner
    include VirtualMonkey::DeploymentRunner
    include VirtualMonkey::EBS
    attr_accessor :scripts_to_run
    attr_accessor :db_ebs_prefix
    attr_accessor :s_one
    attr_accessor :s_two

    # sets the lineage for the deployment
    # * kind<~String> can be "chef" or nil
    def set_variation_lineage(kind = nil)
      @lineage = "testlineage#{rand(1000000)}"
      if kind == "chef"
        @deployment.set_input('db/backup/lineage', "text:#{@lineage}")
        # unset all server level inputs in the deployment to ensure use of 
        # the setting from the deployment level
        @deployment.servers_no_reload.each do |s|
          s.set_input('db/backup/lineage', "text:")
        end
      else
        @deployment.set_input('DB_LINEAGE_NAME', "text:#{@lineage}")
        # unset all server level inputs in the deployment to ensure use of 
        # the setting from the deployment level
        @deployment.servers_no_reload.each do |s|
          s.set_input('DB_LINEAGE_NAME', "text:")
        end
      end
    end

    def set_variation_backup_prefix
      @lineage = "text:testlineage#{rand(1000000)}"
      @deployment.set_input('DB_EBS_PREFIX', @lineage)
      # unset all server level inputs in the deployment to ensure use of 
      # the setting from the deployment level
      @deployment.servers_no_reload.each do |s|
        s.set_input('DB_EBS_PREFIX', "text:")
      end
    end

    def set_variation_bucket
       bucket = "text:testingcandelete#{@deployment.href.split(/\//).last}"
      @deployment.set_input('remote_storage/default/container', bucket)
      # unset all server level inputs in the deployment to ensure use of 
      # the setting from the deployment level
      @deployment.servers_no_reload.each do |s|
        s.set_input('remote_storage/default/container', "text:")
      end
    end

    # creates a MySQL enabled EBS stripe on the server
    # * server<~Server> the server to create stripe on
    def create_stripe(server)
      options = { "EBS_MOUNT_POINT" => "text:/mnt/mysql", 
              "EBS_STRIPE_COUNT" => "text:#{@stripe_count}", 
              "EBS_VOLUME_SIZE_GB" => "text:1", 
              "DBAPPLICATION_USER" => "text:someuser", 
              "DB_MYSQLDUMP_BUCKET" => "ignore:$ignore",
              "DB_MYSQLDUMP_FILENAME" => "ignore:$ignore",
              "AWS_ACCESS_KEY_ID" => "ignore:$ignore",
              "AWS_SECRET_ACCESS_KEY" => "ignore:$ignore",
              "DB_SCHEMA_NAME" => "ignore:$ignore",
              "DBAPPLICATION_PASSWORD" => "text:somepass", 
              "EBS_TOTAL_VOLUME_GROUP_SIZE_GB" => "text:1",
              "EBS_LINEAGE" => "text:#{@lineage}" }
      server.run_executable(@scripts_to_run['create_mysql_ebs_stripe'], options)
    end

    # Performs steps necessary to bootstrap a MySQL Master server from a pristine state.
    # * server<~Server> the server to use as MASTER
    def config_master_from_scratch(server)
      create_stripe(server)
      run_query("create database mynewtest", server)
      set_master_dns(server)
      # This sleep is to wait for DNS to settle - must sleep
      sleep 120
      run_script("backup", server)
    end

    def run_promotion_operations
      config_master_from_scratch(@s_one)
      @s_one.relaunch
      @s_one.dns_name = nil
      wait_for_snapshots(@lineage)
# need to wait for ebs snapshot, otherwise this could easily fail
      restore_server(@s_two)
      @s_one.wait_for_operational_with_dns
      wait_for_snapshots(@lineage)
      slave_init_server(@s_one)
      promote_server(@s_one)
    end

    def run_reboot_operations
      reboot_all
      wait_for_all("operational")
      # This sleep is for waiting for the slave to catch up to the master since they both reboot at once
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

    # Runs a mysql query on specified server.
    # * query<~String> a SQL query string to execute
    # * server<~Server> the server to run the query on 
    def run_query(query, server)
      query_command = "echo -e \"#{query}\"| mysql"
      server.spot_check_command(query_command)
    end

    # Sets DNS record for the Master server to point at server
    # * server<~Server> the server to use as MASTER
    def set_master_dns(server)
      audit = server.run_executable(@scripts_to_run['master_init'])
      audit.wait_for_completed
    end

    def setup_server_vars
      @s_one=@servers[0]
      @s_two=@servers[1]
    end
    # lookup all the RightScripts that we will want to run
    def lookup_scripts
      st = ServerTemplate.find(@s_two.server_template_href)
      @scripts_to_run = {}
      @scripts_to_run['restore'] = st.executables.detect { |ex| ex.name =~  /restore and become/i }
      @scripts_to_run['slave_init'] = st.executables.detect { |ex| ex.name =~ /slave init v2/ }
      @scripts_to_run['promote'] = st.executables.detect { |ex| ex.name =~ /promote to master/ }
      @scripts_to_run['backup'] = st.executables.detect { |ex| ex.name =~ /EBS backup/ }
      @scripts_to_run['terminate'] = st.executables.detect { |ex| ex.name =~ /TERMINATE/ }
      # hardwired script! (this is an 'anyscript' that users typically use to setup the master dns)
      @scripts_to_run['master_init'] = RightScript.new('href' => "/api/acct/2901/right_scripts/195053")
      @scripts_to_run['create_stripe'] = RightScript.new('href' => "/api/acct/2901/right_scripts/198381")
      @scripts_to_run['create_mysql_ebs_stripe'] = RightScript.new('href' => "/api/acct/2901/right_scripts/212492")
      tbx = ServerTemplate.find_by(:nickname) { |n| n =~ /MySQL EBS Toolbox v2/ }
      # Use the HEAD revision.
      @scripts_to_run['create_migrate_script'] = tbx[0].executables.detect { |ex| ex.name =~ /DB EBS create migrate script from MySQL EBS v1 master/ }
    end

    # Use the termination script to stop all the servers (this cleans up the volumes)
    def stop_all
      if @scripts_to_run['terminate']
        @servers.each { |s| s.run_executable(@scripts_to_run['terminate']) unless s.state == 'stopped' }
      else
        @servers.each { |s| s.stop }
      end

      @servers.each { |s| s.wait_for_state("stopped") }
      # unset dns in our local cached copy..
      @servers.each { |s| s.params['dns-name'] = nil } 
    end

    # uses SharedDns to find an available set of DNS records and sets them on the deployment
    def setup_dns
      @dns = SharedDns.new
      raise "Unable to reserve DNS" unless @dns.reserve_dns
      @dns.set_dns_inputs(@deployment)
    end

    # releases records back into the shared DNS pool
    def release_dns
      @dns.release_dns
    end

    def run_checks
      #check monitoring is enabled on all servers
      @servers.each do |server|
        server.settings
        server.monitoring
      end

      # check that mysql tmpdir is custom setup on all servers
      query = "show variables like 'tmpdir'"
      query_command = "echo -e \"#{query}\"| mysql"
      @servers.each do |server|
        server.spot_check(query_command) { |result| raise "Failure: tmpdir was unset#{result}" unless result.include?("/mnt/mysqltmp") }
      end
    end

    def promote_server(server)
      run_script("promote", server)
    end

    def slave_init_server(server)
      run_script("slave_init", server)
    end

    def restore_server(server)
      run_script("restore", server)
    end

    def create_migration_script
      options = { "DB_EBS_PREFIX" => "text:regmysql",
              "DB_EBS_SIZE_MULTIPLIER" => "text:1",
              "EBS_STRIPE_COUNT" => "text:#{@stripe_count}" }
      @s_one.run_executable(@scripts_to_run['create_migrate_script'], options)
    end

    def migrate_slave
      @s_one.settings
      @s_one.spot_check_command("/tmp/init_slave.sh")
      run_script("backup", @s_one)
    end
   
    def launch_v2_slave
      @s_two.settings
      wait_for_snapshots(@lineage)
      run_script("slave_init",@s_two)
    end
  end
end
