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
    Then I should set a variation MySQL DNS
    Then I should launch all servers
    Then I should wait for the state of "all" servers to be "operational"
    Then I should test promotion operations on the deployment
    Then I should run mysql checks

#
# PHASE 2) Reboot
#

    Then I should test reboot operations on the deployment
