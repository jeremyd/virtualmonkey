#@mysql_5.x
#Feature: mysql toolbox
#  Tests the RightScale premium ServerTemplate
#
#  Scenario: Run all toolbox scripts
##
## PHASE 1) Launch a few DB servers.  Make one the master.
##
# Given A MySQL Toolbox deployment
  @runner = VirtualMonkey::MysqlToolboxRunner.new(ENV['DEPLOYMENT'])

# Then I should set a variation MySQL DNS
  @runner.set_var(:setup_dns, "virtualmonkey_shared_resources") # DNSMadeEasy

# Then I should set a variation lineage
  @runner.set_var(:set_variation_lineage)

# Then I should set a variation stripe count of "3"
  @runner.set_var(:set_variation_stripe_count, 3)

# Then I should set a variation volume size "3"
  @runner.set_var(:set_variation_volume_size, 3)

# Then I should stop the servers
  @runner.behavior(:stop_all)

# Then I should launch all servers
  @runner.behavior(:launch_all)

# Then I should wait for the state of "all" servers to be "operational"
  @runner.behavior(:wait_for_all, "operational")

# Then I should create master from scratch
  @runner.behavior(:create_master)

##
## PHASE 2) Run checks for the basic scripts
##
### TODO We need a non-mysql server that doesn't have continuous backups enabled
## Then I should test the backup script operations
#  @runner.behavior(:test_backup_script_operations)
#
##
## PHASE 3) restore the snapshot on another server
##
# Then I should backup the volume
  @runner.behavior(:create_backup)

## Then I should test the restore operations
#  @runner.behavior(:test_restore)
#
##
## PHASE 4) Do the grow EBS tests
##
# Then I should test the restore grow operations
  @runner.behavior(:test_restore_grow)

## Then I should stop the servers
#  @runner.behavior(:stop_all)
