@lb_test

Feature: PHP Chef Server Template
  Tests the deployment

Scenario: PHP Chef Server Templates, PHP FrontEnd and PHP App

  Given A PHP Chef deployment
  Then I should stop the servers
  Then I should set a variation for connecting to shared database host

  Then I should launch the deployment

  Then I should cross connect the frontends

  Then I should run unified application checks
  Then I should run frontend checks
  Then I should run log rotation checks

  Then I should test reboot operations on the deployment
  Then I should check that monitoring is enabled
