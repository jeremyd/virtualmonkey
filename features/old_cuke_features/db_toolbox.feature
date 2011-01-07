@mysql_5.x
Feature: mysql toolbox
  Tests the RightScale premium ServerTemplate

  Scenario: Run all toolbox scripts
#
# PHASE 1) Launch a few DB servers.  Make one the master.
#
    Given A MySQL Toolbox deployment
    Then I should set a variation MySQL DNS
    Then I should set a variation lineage
    Then I should set a variation stripe count of "3"
    Then I should set a variation volume size "3"

    Then I should stop the servers
    Then I should launch all servers
    Then I should wait for the state of "all" servers to be "operational"
    Then I should create master from scratch

#
# PHASE 2) Run checks for the basic scripts
#
# We need a non-mysql server that doesn't have continuous backups enabled
#   Then I should test the backup script operations

#
# PHASE 3) restore the snapshot on another server
#
   Then I should backup the volume
#   Then I should test the restore operations

#
# PHASE 4) Do the grow EBS tests
#
    Then I should test the restore grow operations
#
#
#    Then I should stop the servers
