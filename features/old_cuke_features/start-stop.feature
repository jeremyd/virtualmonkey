@base

Feature: Base Server Test
  Tests the base server functions

Scenario: base server test

  Given A simple deployment
#  Then I should stop the servers
#  Then I should relaunch all servers
  Then I should launch all servers
  Then I should wait for the state of "all" servers to be "operational"
  Then I should perform start stop operations.
