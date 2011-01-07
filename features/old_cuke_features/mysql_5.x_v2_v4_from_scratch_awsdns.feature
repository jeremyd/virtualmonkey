@mysql_5.x
Feature: mysql 5.x v2 or v4 promote operations test
  Tests the RightScale premium ServerTemplate

  Scenario: Setup 2 server deployment and run basic cluster failover operations
#
# PHASE 1) Bootstrap and test promote
#
    Given A MySQL deployment
    Then I should stop the servers
    Then I should set a variation lineage
    Then I should set a variation stripe count of "1"
    Then I should set a variation AWSDNS provider
    Then I should launch all servers
    Then I should wait for the state of "all" servers to be "booting"
    Then I should wait for the state of "all" servers to be "operational"
    Then I should test promotion operations on the deployment
    Then I should run mysql checks
#    Then I should run mysqlslap stress test
    Then I should check that ulimit was set correctly
    Then I should check that monitoring is enabled

#
# PHASE 2) Reboot
#

    Then I should test reboot operations on the deployment

#
# PHASE 3) Additional Tests
#

    Then I should run a restore using OPT_DB_RESTORE_TIMESTAMP_OVERRIDE
