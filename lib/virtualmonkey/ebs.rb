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

    # * server<~Server> the server to restore to
    # * lineage<~String> the lineage to restore from
    # * mnt<~String> the mount point to backup
    def terminate_server(server,count,mnt)
      options = { "EBS_MOUNT_POINT" => "text:#{mnt}",
              "EBS_STRIPE_COUNT" => "text:#{count}",
              "EBS_TERMINATE_SAFETY" => "text:off" }
      audit = server.run_executable(@scripts_to_run['terminate'], options)
      audit.wait_for_completed
    end

    # Terminates a server using the terminate/suicide script
    # * server<~Server> the server to terminate
    def terminate_server_and_wait
      server=@servers.last
      terminate_server(server,@stripe_count,@mount_point)
      server.wait_for_state("stopped")
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

    # take the lineage name, find all snapshots and sleep until none are in the pending state.
    def wait_for_snapshots
      timeout=1500
      step=10
      while timeout > 0
        puts "Checking for snapshot completed"
        snapshots =Ec2EbsSnapshot.find_by_cloud_id(@servers.first.cloud_id).select { |n| n.nickname =~ /#{@lineage}.*$/ }
        status= snapshots.map &:aws_status
        break unless status.include?("pending")
        sleep step
        timeout -= step
      end
      raise "FATAL: timed out waiting for all snapshots in lineage #{@lineage} to complete" if timeout == 0
    end

    # * server<~Server> the server to backup
    def create_backup
      server = @servers.first
      run_script("backup",server)
      wait_for_snapshots
    end

    # * server<~Server> the server to restore to
    # * lineage<~String> the lineage to restore from
    # * mnt<~String> the mount point to backup
    def restore_from_backup(server,lineage,mnt)
      options = { "EBS_MOUNT_POINT" => "text:#{mnt}", 
              "EBS_LINEAGE" => "text:#{lineage}" }
      audit = server.run_executable(@scripts_to_run['create_stripe'], options)
      audit.wait_for_completed
    end

    def restore_and_test_volume
      server=@servers.last
      restore_from_backup(server,@lineage,@mount_point)
      server.spot_check_command("test -f #{@mount_point}/data.txt")
    end

  end
end
