#@ebs
#Feature: EBS toolbox tests
#  Tests the RightScale premium ServerTemplate
#
#  Scenario: Run all EBS toolbox operational scripts
##
## PHASE 1) Launch a toolbox server and create an EBS stripe with "interesting" data on it.
##  How many servers do we need?  Launch them all and figure it out later.
##
# Given A EBS Toolbox deployment
  @runner = VirtualMonkey::EBSRunner.new(ENV['DEPLOYMENT'])

# Then I should set a variation lineage
  @runner.set_var(:set_variation_lineage)

# Then I should set a variation stripe count of "3"
  @runner.set_var(:set_variation_stripe_count, 3)

# Then I should set a variation volume size "3"
  @runner.set_var(:set_variation_volume_size, 3)

# Then I should set a variation mount point "/mnt/ebs"
  @runner.set_var(:set_variation_mount_point, "/mnt/ebs")

# Then I should stop the servers
  @runner.behavior(:stop_all)

# Then I should launch all servers
  @runner.behavior(:launch_all)

# Then I should wait for the state of "all" servers to be "operational"
  @runner.behavior(:wait_for_all, "operational")

# Then I should create a new EBS stripe
  @runner.behavior(:create_stripe)

##
## PHASE 2) Run checks for the basic scripts
##
# Then I should test the backup script operations
  @runner.behavior(:test_backup_script_operations)

##
## PHASE 3) restore the snapshot on another server
##
# Then I should backup the volume
  @runner.behavior(:create_backup)

# Then I should test the restore operations
  @runner.behavior(:test_restore)

##
## PHASE 4) Do the grow EBS tests
##
# Then I should test the restore grow operations
  @runner.behavior(:test_restore_grow)

# Then I should test reboot operations on the deployment
  @runner.behavior(:run_reboot_operations)

# Then I should stop the servers
  @runner.behavior(:stop_all)
