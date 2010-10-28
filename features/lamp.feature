@lamp_test

Feature: LAMP Server Template Test
  Tests the deployment

Scenario: LAMP Server Template Test

  Given A LAMP deployment
  Then I should stop the servers
  Then I should launch all servers
  Then I should wait for the state of "all" servers to be "operational"
  Then I should run LAMP checks
  Then I should run mysql checks
#  Then I should run mysqlslap stress test
  Then I should check that ulimit was set correctly
