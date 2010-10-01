@rightlink
Feature: RightLink Feature Tests

  Make sure rightlink supports the expected functionality 

  Scenario: The RightLink Test template should go operational
    Given A simple deployment
    Then I should stop the servers
    Then I should launch all servers
    Then I should wait for the state of "all" servers to be "operational"
    Then I should check that monitoring is enabled
