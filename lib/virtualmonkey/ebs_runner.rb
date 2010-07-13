require 'ruby-debug'

module VirtualMonkey
  class EBSRunner
    include VirtualMonkey::DeploymentRunner
    include VirtualMonkey::EBS
    attr_accessor :scripts_to_run
    attr_accessor :lineage
    attr_accessor :ebs_prefix
    attr_accessor :volume_size
    attr_accessor :mount_point

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

    # sets the EBS mount point for the runner
    # * kind<~String> 
    def set_variation_mount_point(mnt)
      @mount_point = mnt
    end

    # sets the volume size n GB for the runner
    # * kind<~Num> 
    def set_variation_volume_size(size)
      @volume_size = size
    end

    # creates a EBS stripe on the server
    # * server<~Server> the server to create stripe on
    # * mnt<~String> the location to mount the new stripe
    def create_stripe(server,mnt)
      options = { "EBS_MOUNT_POINT" => "text:#{mnt}", 
              "EBS_STRIPE_COUNT" => "text:#{@stripe_count}", 
              "EBS_TOTAL_VOLUME_GROUP_SIZE_GB" => "text:1",
              "EBS_LINEAGE" => "text:#{@lineage}" }
      audit = server.run_executable(@scripts_to_run['create_stripe'], options)
      audit.wait_for_completed
    end
    # Writes data to the EBS volume so snapshot restores can be verified
    # Not sure what to write...... Maybe pass a string to write to a file??..
    def populate_volume(server,mnt)
       server.spot_check_command(" echo \"blah blah blah\" > #{mnt}/data.txt")
    end

    # Create a stripe and write some data to it
    def create_stripe_with_data
      create_stripe(@servers.first,@mount_point)
      populate_volume(@servers.first,@mount_point)
    end

    # lookup all the RightScripts that we will want to run
    def lookup_scripts
      st = ServerTemplate.find(@servers.first.server_template_href)
      @scripts_to_run = {}
      @scripts_to_run['backup'] = st.executables.detect { |ex| ex.name =~ /EBS volume backup/ }
      @scripts_to_run['restore'] = st.executables.detect { |ex| ex.name =~  /EBS volume restore/i }
      @scripts_to_run['continuous_backup'] = st.executables.detect { |ex| ex.name =~  /EBS continuous backups/i }
      @scripts_to_run['unfreeze'] = st.executables.detect { |ex| ex.name =~  /EBS unfreeze volume backups/i }
      @scripts_to_run['freeze'] = st.executables.detect { |ex| ex.name =~  /EBS freeze volume backups/i }
      @scripts_to_run['create_stripe'] = st.executables.detect { |ex| ex.name =~  /EBS Stripe create/i }
      @scripts_to_run['create_backup_scripts'] = st.executables.detect { |ex| ex.name =~  /EBS create backup scripts/i }
      @scripts_to_run['grow_volume'] = st.executables.detect { |ex| ex.name =~  /EBS volume grow and restore/i }
      @scripts_to_run['terminate'] = st.executables.detect { |ex| ex.name =~ /TERMINATE/ }
    end

    def test_backup_script_operations
      server=@servers.first
      backup_script="/usr/local/bin/ebs-backup.rb"
# create backup scripts
      run_script("create_backup_scripts",server)
      server.spot_check_command("test -x #{backup_script}")
# enable continuous backups
      run_script("continuous_backup",server)
      server.spot_check_command("egrep \"^[0-6].*#{backup_script}\" /etc/crontab")
# freeze backups
      run_script("freeze",server)
      server.spot_check_command("egrep \"^#[0-6].*#{backup_script}\" /etc/crontab")
# unfreeze backups
      run_script("unfreeze",server)
      server.spot_check_command("egrep \"^[0-6].*#{backup_script}\" /etc/crontab")
    end

    def restore_and_grow(server,lineage,size,mnt)
      options = { "EBS_MOUNT_POINT" => "text:#{mnt}",
              "EBS_TOTAL_VOLUME_GROUP_SIZE_GB" => "text:#{size}",
              "EBS_LINEAGE" => "text:#{lineage}" }
      audit = server.run_executable(@scripts_to_run['grow_volume'], options)
      audit.wait_for_completed
    end    

    def restore_grow_and_test
      restore_and_grow(@servers.last,@lineage,100,@mount_point)
# TODO - make this a function - used in multiple places
      server.spot_check_command("test -f #{@mount_point}/data.txt")
    end
  end
end
