@php_aio_trial_chef_test

Feature: PHP AIO Trial (Chef Alpha) Server Template Test
  Tests the deployment

Scenario: PHP AIO Trial Server Template test

  Given A PHP AIO Trial Chef deployment
  Then I should stop the servers
  Then I should launch all servers
  Then I should wait for the state of "all" servers to be "operational"
