Feature: Terminates all servers in all deployments
  Terminate all

Scenario: stop all

  Given A simple deployment
  Then I should stop the servers
