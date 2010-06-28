@lb_test

Feature: PHP Server Test
  Tests the PHP servers

Scenario: PHP server test

  Given A frontend with application servers deployment
  Then I should set a variation MASTER_DB_DNSNAME 

  When I launch the "Front End" servers
  Then I should wait for the state of "Front End" servers to be "operational"
  Then I should set a variation LB_HOSTNAME
  When I launch the "App Server" servers
  Then I should wait for the state of "App Server" servers to be "operational"
  Then I should cross connect the frontends

  Then I should run unified application checks
  Then I should run frontend checks
  Then I should run log rotation checks

  Then I should test reboot operations on the deployment
