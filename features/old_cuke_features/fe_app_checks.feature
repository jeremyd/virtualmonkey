@lb_test

Feature: PHP Server Test
  Tests the PHP servers (checks only).  Assumes all servers are already operational or can be launched to operational and have the correct config.

Scenario: PHP server test (checks only)

  Given A frontend with application servers deployment

  When I launch the "Front End" servers
  Then I should wait for the state of "Front End" servers to be "operational"

  When I launch the "App Server" servers
  Then I should wait for the state of "App Server" servers to be "operational"

# Optional:
#  Then I should cross connect the frontends

  Then I should run unified application checks
  Then I should run frontend checks
  Then I should run log rotation checks
