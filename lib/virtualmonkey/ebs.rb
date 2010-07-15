require 'ruby-debug'

module VirtualMonkey
  module EBS
    include VirtualMonkey::DeploymentRunner
    attr_accessor :stripe_count
    attr_accessor :volume_size
    attr_accessor :mount_point
    attr_accessor :lineage

    # sets the stripe count for the deployment
    # * count<~String> eg. "3"
    def set_variation_stripe_count(count)
      @stripe_count = count
      @deployment.set_input("EBS_STRIPE_COUNT", "text:#{@stripe_count}")
    end

    # sets the volume size n GB for the runner
    # * kind<~Num> 
    def set_variation_volume_size(size)
      @volume_size = size
    end

    # sets the EBS mount point for the runner
    # * kind<~String> 
    def set_variation_mount_point(mnt)
      @mount_point = mnt
    end

    # sets the lineage for the deployment
    # * kind<~String> can be "chef" or nil
    def set_variation_lineage(kind = nil)
      @lineage = "testlineage#{rand(1000000)}"
      if kind
        raise "Only support nil kind for ebs lineage"
      else
        @deployment.set_input('EBS_LINEAGE', "text:#{@lineage}")
        # unset all server level inputs in the deployment to ensure use of 
        # the setting from the deployment level
        @deployment.servers_no_reload.each do |s|
          s.set_input('EBS_LINEAGE', "text:")
        end
      end
    end

    # take the lineage name, find all snapshots and sleep until none are in the pending state.
    # * lineage<~String> the snapshot lineage
    def wait_for_snapshots(lineage)
      timeout=1500
      step=10
      while timeout > 0
        puts "Checking for snapshot completed"
        snapshots =Ec2EbsSnapshot.find_by_cloud_id(@servers.first.cloud_id).select { |n| n.nickname =~ /#{lineage}.*$/ }
        status= snapshots.map &:aws_status
        break unless status.include?("pending")
        sleep step
        timeout -= step
      end
      raise "FATAL: timed out waiting for all snapshots in lineage #{lineage} to complete" if timeout == 0
    end

    # creates a EBS stripe on the server
    # * server<~Server> the server to create stripe on
    # * mnt<~String> the location to mount the new stripe
    def create_stripe_volume(server,count,size,mnt,lineage)
      options = { "EBS_MOUNT_POINT" => "text:#{mnt}",
              "EBS_STRIPE_COUNT" => "text:#{count}",
              "EBS_TOTAL_VOLUME_GROUP_SIZE_GB" => "text:#{size}",
              "EBS_LINEAGE" => "text:#{lineage}" }
      audit = server.run_executable(@scripts_to_run['create_stripe'], options)
      audit.wait_for_completed
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

    def restore_and_grow(server,lineage,size,mnt)
      options = { "EBS_MOUNT_POINT" => "text:#{mnt}",
              "EBS_TOTAL_VOLUME_GROUP_SIZE_GB" => "text:#{size}",
              "EBS_LINEAGE" => "text:#{lineage}" }
      audit = server.run_executable(@scripts_to_run['grow_volume'], options)
      audit.wait_for_completed
    end

    # Verify that the volume has special data on it.
    def test_volume_data(server,mnt)
      server.spot_check_command("test -f #{mnt}/data.txt")
    end

    # Writes data to the EBS volume so snapshot restores can be verified
    # Not sure what to write...... Maybe pass a string to write to a file??..
    def populate_volume(server,mnt)
       server.spot_check_command(" echo \"blah blah blah\" > #{mnt}/data.txt")
    end

    # * server<~Server> the server to terminate
    # * count<~Num> the stripe count - TODO - IS THIS NEEDED
    # * mnt<~String> the mount point to backup
    def terminate_server(server,count,mnt)
      options = { "EBS_MOUNT_POINT" => "text:#{mnt}",
              "EBS_STRIPE_COUNT" => "text:#{count}",
              "EBS_TERMINATE_SAFETY" => "text:off" }
      audit = server.run_executable(@scripts_to_run['terminate'], options)
      audit.wait_for_completed
    end

    # Use the termination script to stop all the servers (this cleans up the volumes)
    def stop_all
      @servers.each do |s|
        terminate_server(s,@stripe_count,@mount_point) unless s.state == 'stopped'
      end
      @servers.each { |s| s.wait_for_state("stopped") }
      # unset dns in our local cached copy..
      @servers.each { |s| s.params['dns-name'] = nil }
    end

  end
end
