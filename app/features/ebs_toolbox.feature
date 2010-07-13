@ebs
Feature: EBS toolbox tests
  Tests the RightScale premium ServerTemplate

  Scenario: Run all EBS toolbox operational scripts
#
# PHASE 1) Launch a toolbox server and create an EBS stripe with "interesting" data on it.
#  How many servers do we need?  Launch them all and figure it out later.
#
    Given A EBS Toolbox deployment
#    Then I should stop the servers
    Then I should set a variation lineage
    Then I should set a variation stripe count of "3"
    Then I should set a variation EBS volume size "3"
    Then I should set a variation EBS mount point "/mnt/ebs"
    Then I should launch all servers
    Then I should wait for the state of "all" servers to be "operational"
    Then I should create a new EBS stripe with data

#
# PHASE 2) Run checks for the basic scripts
#
   Then I should test the backup script operations

#
# PHASE 3) restore the snapshot on another server
#
   Then I should backup the volume
   Then I should restore and test the volume

#
# PHASE 4) Do the grow EBS tests
#
    Then I should stop the servers
    Then I should launch all servers
    Then I should wait for the state of "all" servers to be "operational"
    Then I should restore grow and test the volume
#
#
#  Then I should terminate the server
