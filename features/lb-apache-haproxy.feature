@lb_test

Feature: LB Server Test
  Tests the LB servers

Scenario: LB server test

  Given An Apache with HAproxy deployment
  Then I should stop the servers
  Then I should set a variation for connecting to shared database host

  When I launch the "Apache" servers
#  Then the "Apache" servers become operational
  Then I should wait for the state of "Apache" servers to be "operational"

  Then I should set a variation LB_HOSTNAME
  When I launch the "App Server" servers
  Then I should wait for the state of "App Server" servers to be "operational"

  Then I should run unified application checks
  Then I should run frontend checks
  Then I should run log rotation checks

# TODO?
  #When I restart apache
  #Then apache status should be good

  Then I should test reboot operations on the deployment
