#@mysql_5.x
#Feature: mysql 5.x v1 to v2 upgrade tests
#  Tests the RightScale premium ServerTemplate
#
#  Scenario: Follow the steps in the v1 to v2 upgrade guide. Then run the mysql checks.
# http://support.rightscale.com/03-Tutorials/02-AWS/02-Website_Edition/2.1_MySQL_Setup/MySQL_Setup_Migration%3a__EBS_to_EBS_Stripe
#
# PHASE 1) Launch a v1 master from a known hardcoded snapshot.
#  TODO - add the steps to create the v1 master from scratch.  The upgrade is the major
#         concern so lets get that done first.
#  Prerequisite: A Deployment with a running MySQL EBS Master-DB server 
#  (launched using a revision of the "MySQL EBS v1" ServerTemplate)
# Old school hand crafted deployment: https://my.rightscale.com/deployments/49925.  Make sure
# The one server is still up and running as master DB.
#
# Given A MySQL deployment
  @runner = VirtualMonkey::MysqlRunner.new(ENV['DEPLOYMENT'])
  @runner.behavior(:lookup_scripts)

# Then I should stop the servers
  @runner.behavior(:stop_all)

# Then I should set a variation lineage
  @runner.behavior(:set_variation_lineage)

# Then I should set a variation stripe count of "3"
  @runner.behavior(:set_variation_stripe_count, 3)

#
# PHASE 2) Launch a new v2 server and migrate from v1
#
# Then I should launch all servers
  @runner.behavior(:launch_all)

# Then I should wait for the state of "all" servers to be "operational"
  @runner.behavior(:wait_for_all, "operational")

# Then I should create the migration script
  @runner.behavior(:create_migration_script)

# Then I should migrate a new slave
  @runner.behavior(:migrate_slave)

#
# PHASE 3) Initialize additional slave from v2 snapshots
#
# Then I should init a new v2 slave
  @runner.behavior(:launch_v2_slave)

# Then I should test the new v2 slave
  @runner.behavior(:run_checks)

# Then I should check that ulimit was set correctly
  @runner.behavior(:ulimit_check)

