require 'ruby-debug'
module VirtualMonkey
  module Mysql
    include VirtualMonkey::DeploymentRunner
    include VirtualMonkey::EBS
    attr_accessor :scripts_to_run
    attr_accessor :db_ebs_prefix

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
      server.spot_check_command("service mysql start")
      run_query("create database mynewtest", server)
      set_master_dns(server)
      # This sleep is to wait for DNS to settle - must sleep
      sleep 120
      run_script("backup", server)
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

    # Use the termination script to stop all the servers (this cleans up the volumes)
    def stop_all(wait=true)
      if @scripts_to_run['terminate']
        options = { "DB_TERMINATE_SAFETY" => "text:off" }
        @servers.each { |s| s.run_executable(@scripts_to_run['terminate'], options) unless s.state == 'stopped' }
      else
        @servers.each { |s| s.stop }
      end

      wait_for_all("stopped") if wait
      # unset dns in our local cached copy..
      @servers.each { |s| s.params['dns-name'] = nil } 
    end

    # uses SharedDns to find an available set of DNS records and sets them on the deployment
    def setup_dns
      owner="Erik"
      @dns = SharedDns.new
      raise "Unable to reserve DNS" unless @dns.reserve_dns(owner)
      @dns.set_dns_inputs(@deployment)
    end

    # releases records back into the shared DNS pool
    def release_dns
      @dns.release_dns
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
      s_one.run_executable(@scripts_to_run['create_migrate_script'], options)
    end
  end
end
