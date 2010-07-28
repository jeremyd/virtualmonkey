module VirtualMonkey
  class EBSRunner
    include VirtualMonkey::DeploymentRunner
    include VirtualMonkey::EBS
    attr_accessor :scripts_to_run

    # lookup all the RightScripts that we will want to run
    def lookup_scripts
      st = ServerTemplate.find(s_one.server_template_href)
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
    
    # Create a stripe and write some data to it
    def create_stripe
      create_stripe_volume(s_one)
      populate_volume(s_one)
    end

    def test_backup_script_operations
      backup_script="/usr/local/bin/ebs-backup.rb"
# create backup scripts
      run_script("create_backup_scripts",s_one)
      s_one.spot_check_command("test -x #{backup_script}")
# enable continuous backups
      run_script("continuous_backup",s_one)
      s_one.spot_check_command("egrep \"^[0-6].*#{backup_script}\" /etc/crontab")
# freeze backups
      run_script("freeze",s_one)
      s_one.spot_check_command("egrep \"^#[0-6].*#{backup_script}\" /etc/crontab")
# unfreeze backups
      run_script("unfreeze",s_one)
      s_one.spot_check_command("egrep \"^[0-6].*#{backup_script}\" /etc/crontab")
    end

    def run_reboot_operations
      s_one.reboot(true)
      s_one.wait_for_state("operational")
      create_backup
    end

  end
end
