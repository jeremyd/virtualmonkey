#@elb_test
#
#Feature: PHP App Server Elastic Load Balancing test
#  Tests the Elastic Load Balancing RightScripts using PHP App Server 
#
#Scenario: Connect/Disconnect PHP App Server to ELB
#
# Given An ELB Test deployment
  @runner = VirtualMonkey::ELBRunner.new(ENV['DEPLOYMENT']) 

# When I create EC2 Elastic Load Balancer
  @runner.set_var(:create_elb)
  
# Then I should stop the servers
  @runner.set_var(:stop_all)

# Then I should set a variation for connecting to shared database host 
  @runner.set_var(:set_master_db_dnsname)

# Then I should set a variation ELB_NAME
  @runner.set_var(:set_elb_name)

# When I launch the "App Server" servers
  @runner.behavior(:launch_set, "App Server")

# Then I should wait for the state of "App Server" servers to be "booting"
  @runner.behavior(:wait_for_set, "App Server", "booting")

# Then I should wait for the state of "App Server" servers to be "operational"
  @runner.behavior(:wait_for_set, "App Server", "operational")
 
# Then I should run EC2 Elastic Load Balancer unified_app checks
  @runner.behavior(:run_elb_checks)

# Then all instances should be registered with ELB
  @runner.behavior(:elb_registration_check, :all)

## Then I should run log rotation checks
#  @runner.behavior(:log_rotation_checks)
#
## Then I should check that monitoring is enabled
#  @runner.behavior(:check_monitoring)
#
## Then I should reboot the servers
#  @runner.behavior(:reboot_all)
#
## Then I should run EC2 Elastic Load Balancer unified_app checks
#  @runner.behavior(:run_elb_checks)
#
## Then all instances should be registered with ELB
#  @runner.behavior(:elb_registration_check, :all)
#
## Then I should run log rotation checks
#  @runner.behavior(:log_rotation_checks)
#
## Then I should check that monitoring is enabled
#  @runner.behavior(:check_monitoring)
#
# Then I should stop the servers
  @runner.behavior(:stop_all)

# Then no instances should be registered with ELB
  @runner.behavior(:elb_registration_check, :none)

# When I delete EC2 Elastic Load Balancer
  @runner.behavior(:destroy_elb)

## When I launch the "App Server" servers
#  @runner.behavior(:launch_set, "App Server")
#
## When I should wait for the state of "App Server" servers to be "booting"
#  @runner.behavior(:wait_for_set, "App Server", "booting")
#
## Then I should wait for the state of "App Server" servers to be "stranded"
#  @runner.behavior(:wait_for_set, "App Server", "stranded")
#
## Then I should stop the servers
#  @runner.behavior(:stop_all)
