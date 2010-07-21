require 'ruby-debug'

module VirtualMonkey
  class EBSRunner
    include VirtualMonkey::DeploymentRunner
    include VirtualMonkey::EBS
    attr_accessor :scripts_to_run
    attr_accessor :s_main
    attr_accessor :s_restore
    attr_accessor :s_grow

    # lookup all the RightScripts that we will want to run
    def lookup_scripts
      st = ServerTemplate.find(@s_main.server_template_href)
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
    
    # Setup the server vars
    def setup_server_vars
      @s_main = @servers[0]
      @s_restore = @servers[1]
      @s_grow = @servers[2]
      raise "Not enough servers in deployment for test" unless s_main && s_restore && s_grow
    end

    # Create a stripe and write some data to it
    def create_stripe
      create_stripe_volume(@s_main,@stripe_count,@volume_size,@mount_point,@lineage)
      populate_volume(@s_main,@mount_point)
    end

    def test_backup_script_operations
      backup_script="/usr/local/bin/ebs-backup.rb"
# create backup scripts
      run_script("create_backup_scripts",@s_main)
      @s_main.spot_check_command("test -x #{backup_script}")
# enable continuous backups
      run_script("continuous_backup",@s_main)
      @s_main.spot_check_command("egrep \"^[0-6].*#{backup_script}\" /etc/crontab")
# freeze backups
      run_script("freeze",@s_main)
      @s_main.spot_check_command("egrep \"^#[0-6].*#{backup_script}\" /etc/crontab")
# unfreeze backups
      run_script("unfreeze",@s_main)
      @s_main.spot_check_command("egrep \"^[0-6].*#{backup_script}\" /etc/crontab")
    end

    def test_restore_grow
      restore_and_grow(@s_grow,@lineage,100,@mount_point)
      test_volume_data(@s_grow,@mount_point)
    end

    def test_restore
      restore_from_backup(@s_restore,@lineage,@mount_point)
      test_volume_data(@s_restore,@mount_point)
    end
   
    def run_reboot_operations
      @s_main.reboot(true)
      @s_main.wait_for_state("operational")
      create_backup
    end

    def create_backup
      run_script("backup",s_main)
      wait_for_snapshots(@lineage)
    end

  end
end
