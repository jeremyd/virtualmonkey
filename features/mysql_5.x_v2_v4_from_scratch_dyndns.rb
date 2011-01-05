#@mysql_5.x
#Feature: mysql 5.x v2 or v4 promote operations test
#  Tests the RightScale premium ServerTemplate
#
#  Scenario: Setup 2 server deployment and run basic cluster failover operations
#
# PHASE 1) Bootstrap and test promote
#
# Given A MySQL deployment
  @runner = VirtualMonkey::MysqlRunner.new(ENV['DEPLOYMENT'])

# Then I should stop the servers
  @runner.behavior(:stop_all)

# Then I should set a variation lineage
  @runner.set_var(:set_variation_lineage)

# Then I should set a variation stripe count of "1"
  @runner.set_var(:set_variation_stripe_count, 1)

# Then I should set a variation MySQL DNS
  @runner.set_var(:setup_dns, "virtualmonkey_awsdns") # DNSMadeEasy

# Then I should launch all servers
  @runner.behavior(:launch_all)

# Then I should wait for the state of "all" servers to be "booting"
  @runner.behavior(:wait_for_all, "booting")

# Then I should wait for the state of "all" servers to be "operational"
  @runner.behavior(:wait_for_all, "operational")

# Then I should test promotion operations on the deployment
  @runner.behavior(:run_promotion_operations)

# Then I should run mysql checks
  @runner.behavior(:run_checks)

# Then I should run mysqlslap stress test
#  @runner.behavior(:run_mysqlslap_check)

# Then I should check that ulimit was set correctly
#  @runner.behavior(:ulimit_check)
  @runner.probe(".*", "su - mysql -s /bin/bash -c \"ulimit -n\"") { |s| s.to_i > 1024 }

# Then I should check that monitoring is enabled
  @runner.behavior(:check_monitoring)

#
# PHASE 2) Reboot
#

# Then I should test reboot operations on the deployment
  @runner.behavior(:run_reboot_operations)

#
# PHASE 3) Additional Tests
#

# Then I should run a restore using OPT_DB_RESTORE_TIMESTAMP_OVERRIDE
  @runner.behavior(:run_restore_with_timestamp_override)

# 
# PHASE 4) Terminate
#

# Then I should terminate the servers
  @runner.behavior(:stop_all, true)

# Then I should release the DNS
  @runner.behavior(:release_dns)
