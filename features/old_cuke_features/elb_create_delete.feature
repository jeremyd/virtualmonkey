@elb_test

Feature: PHP App Server Elastic Load Balancing test
  Tests the Elastic Load Balancing RightScripts using PHP App Server 

Scenario: Connect/Disconnect PHP App Server to ELB

  Given An ELB Test deployment
  
   When I create EC2 Elastic Load Balancer
  
#   Then I should stop the servers
#   Then I should set a variation for connecting to shared database host 
#   Then I should set a variation ELB_NAME
#   When I launch the "App Server" servers
#   Then I should wait for the state of "App Server" servers to be "booting"
#   Then I should wait for the state of "App Server" servers to be "operational"
# 
#   Then I should run EC2 Elastic Load Balancer unified_app checks
#   Then all instances should be registered with ELB
##   Then I should run log rotation checks
##   Then I should check that monitoring is enabled
#  
##   Then I should reboot the servers
#
##   Then I should run EC2 Elastic Load Balancer unified_app checks
##   Then all instances should be registered with ELB
##   Then I should run log rotation checks
##   Then I should check that monitoring is enabled
# 
#    Then I should stop the servers
#    Then no instances should be registered with ELB
       
    When I delete EC2 Elastic Load Balancer
#    When I launch the "App Server" servers
#    When I should wait for the state of "App Server" servers to be "booting"
#    
#    Then I should wait for the state of "App Server" servers to be "stranded"
#    Then I should stop the servers
    
    
