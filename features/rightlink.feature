@rightlink
Feature: RightLink Feature Tests

  Make sure rightlink supports the expected functionality 

  Scenario: The RightLink Test template should go operational
    Given A simple deployment
    Then I should stop the servers
    Then I should launch all servers
    Then I should wait for the state of "all" servers to be "operational"

    Then all servers should successfully run a recipe named "rightlink_test::state_test_check_value".
    
    When I run a recipe named "rightlink_test::resource_remote_recipe_test_start" on server "1". 
    Then it should converge successfully.   
    Then I should sleep 10 seconds.
    Then I should see "resource_remote_recipe_ping" in the log on server "2".  
    
    Then I should check that monitoring is enabled
