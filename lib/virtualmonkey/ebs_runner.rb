module VirtualMonkey
  class EBSRunner
    include VirtualMonkey::DeploymentRunner
    include VirtualMonkey::EBS
    attr_accessor :scripts_to_run

    # It's not that I'm a Java fundamentalist; I merely believe that mortals should
    # not be calling the following methods directly. Instead, they should use the
    # TestCaseInterface methods (behavior, verify, probe) to access these functions.
    # Trust me, I know what's good for you. -- Tim R.
    private

    # lookup all the RightScripts that we will want to run
    def lookup_scripts
      scripts = [
                 [ 'backup', 'EBS stripe volume backup' ],
                 [ 'restore', 'EBS stripe volume restore' ],
                 [ 'continuous_backup', 'EBS continuous backups' ],
                 [ 'unfreeze', 'EBS unfreeze volume backups' ],
                 [ 'freeze', 'EBS freeze volume backups' ],
                 [ 'create_stripe', 'EBS stripe volume create' ],
                 [ 'create_backup_scripts', 'EBS create backup scripts' ],
                 [ 'grow_volume', 'EBS stripe volume grow and restore' ],
                 [ 'terminate', 'TERMINATE' ]
               ]
      st = ServerTemplate.find(s_one.server_template_href)
      lookup_scripts_table(st,scripts)
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
