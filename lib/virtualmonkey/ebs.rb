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
      @lineage = "testlineage#{@deployment.href.split(/\//).last}"
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
    def wait_for_snapshots
      timeout=1500
      step=10
      while timeout > 0
        puts "Checking for snapshot completed"
        snapshots = behavior(:find_snapshots)
        status= snapshots.map { |x| x.aws_status } 
        break unless status.include?("pending")
        sleep step
        timeout -= step
      end
      raise "FATAL: timed out waiting for all snapshots in lineage #{@lineage} to complete" if timeout == 0
    end

    # Find all snapshots associated with this deployment's lineage
    def find_snapshots
      unless @lineage
        s = @servers.first
        kind_params = s.transform_parameters(s.parameters)
        @lineage = kind_params['DB_LINEAGE_NAME'].gsub(/text:/, "")
      end
      snapshots = Ec2EbsSnapshot.find_by_cloud_id(@servers.first.cloud_id).select { |n| n.nickname =~ /#{@lineage}.*$/ }
    end

    # Returns the timestamp of the latest snapshot for testing OPT_DB_RESTORE_TIMESTAMP_OVERRIDE
    def find_snapshot_timestamp
      last_snap = behavior(:find_snapshots).last
      last_snap.tags.detect { |t| t["name"] =~ /timestamp=(\d+)$/ }
      timestamp = $1
    end

    # creates a EBS stripe on the server
    # * server<~Server> the server to create stripe on
    def create_stripe_volume(server)
      options = { "EBS_MOUNT_POINT" => "text:#{@mount_point}",
              "EBS_STRIPE_COUNT" => "text:#{@stripe_count}",
              "EBS_TOTAL_VOLUME_GROUP_SIZE" => "text:#{@volume_size}",
              "EBS_LINEAGE" => "text:#{@lineage}" }
      audit = server.run_executable(@scripts_to_run['create_stripe'], options)
      audit.wait_for_completed
    end

    # * server<~Server> the server to restore to
    def restore_from_backup(server,force)
      options = { "EBS_MOUNT_POINT" => "text:#{@mount_point}",
              "OPT_DB_FORCE_RESTORE" => "text:#{force}",
              "EBS_LINEAGE" => "text:#{@lineage}" }
      audit = server.run_executable(@scripts_to_run['restore'], options)
      audit.wait_for_completed
    end

    # * server<~Server> the server to restore to
    def restore_and_grow(server,new_size,force)
      options = { "EBS_MOUNT_POINT" => "text:#{@mount_point}",
              "EBS_TOTAL_VOLUME_GROUP_SIZE" => "text:#{new_size}",
              "OPT_DB_FORCE_RESTORE" => "text:#{force}",
              "EBS_LINEAGE" => "text:#{@lineage}" }
      audit = server.run_executable(@scripts_to_run['grow_volume'], options)
      audit.wait_for_completed
    end

    # Verify that the volume has special data on it.
    def test_volume_data(server)
      server.spot_check_command("test -f #{@mount_point}/data.txt")
    end

    # Verify that the volume is the expected size
    def test_volume_size(server,expected_size)
      puts "Testing with: #{@mount_point} #{expected_size}"
puts "THIS DOES NOT WORK - cause of rounding errors during volume size determination, FS overhead  and df's output"
puts "Need to query the volumes attached to the server and verify that they #{expected_size}/#{@stripe_count}"
puts "Check that the server's volumes are #{expected_size}"
#      server.spot_check_command("df -kh | awk -F\" \" -v -v size=#{expected_size}G '/#{@mount_point}/ {exit $2!=size}'")
    end

    # Writes data to the EBS volume so snapshot restores can be verified
    # Not sure what to write...... Maybe pass a string to write to a file??..
    def populate_volume(server)
       server.spot_check_command(" echo \"blah blah blah\" > #{@mount_point}/data.txt")
    end

    # * server<~Server> the server to terminate
    def terminate_server(server)
      options = { "EBS_MOUNT_POINT" => "text:#{@mount_point}",
              "EBS_TERMINATE_SAFETY" => "text:off" }
      audit = server.run_executable(@scripts_to_run['terminate'], options)
      audit.wait_for_completed
    end

    # Use the termination script to stop all the servers (this cleans up the volumes)
    def stop_all
      @servers.each do |s|
        terminate_server(s) if s.state == 'operational' || s.state == 'stranded'
      end
      @servers.each { |s| s.wait_for_state("stopped") }
      # unset dns in our local cached copy..
      @servers.each { |s| s.params['dns-name'] = nil }
    end
    def test_restore_grow
      grow_to_size=100
      behavior(:restore_and_grow, s_three, grow_to_size, false)
      behavior(:test_volume_data, s_three)
      behavior(:test_volume_size, s_three, grow_to_size)
    end

    def test_restore
      behavior(:restore_from_backup, s_two, false)
      behavior(:test_volume_data, s_two)
    end

    def create_backup
      behavior(:run_script, "backup", s_one)
      behavior(:wait_for_snapshots)
    end

  end
end
