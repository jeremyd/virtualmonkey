require 'ruby-debug'

module VirtualMonkey
  module EBS
    include VirtualMonkey::DeploymentRunner
    attr_accessor :stripe_count

    # sets the stripe count for the deployment
    # * count<~String> eg. "3"
    def set_variation_stripe_count(count)
      @stripe_count = count
      @deployment.set_input("EBS_STRIPE_COUNT", "text:#{@stripe_count}")
    end

    # Terminates a server using the terminate/suicide script
    # * server<~Server> the server to terminate
    def terminate_server(server)
      run_script("terminate", server)
      server.stop
      server.dns_name = nil
    end

    # This is where we perform multiple checks on the deployment after a reboot.
    def run_reboot_checks
      # one simple check we can do is the backup.  Backup can fail if anything is amiss
      @servers.each do |server|
        run_script("backup", server)
      end
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

    def run_checks
      #check monitoring is enabled on all servers
      @servers.each do |server|
        server.settings
        server.monitoring
      end
    end

    # Run operational script to enable continuous backups
    def enable_backups
    end

    def verify_backups_enabled
    end

    def freeze_backups
    end

    def verfiy_backups_frozen
    end

    def unfreeze_backups
    end

    def verify_backup_scripts
    end

    # * server<~Server> the server to backup
    def create_backup(server)
    end

    # * server<~Server> the server to restore to
    # * lineage<~String> the lineage to restore from
    def restore_from_backup(server,lineage)
    end

    # * server<~Server> the server to verify the volume data on
    def verify_volume_data(server)
    end

    # * server<~Server> the server to verify is stopped.
    def verify_server_stopped(server)
    end

  end
end
