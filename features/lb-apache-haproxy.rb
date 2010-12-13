#@lb_test
#
#Feature: LB Server Test
#  Tests the LB servers
#
#Scenario: LB server test
#
# Given An Apache with HAproxy deployment
  @runner = VirtualMonkey::FeAppRunner.new(ENV['DEPLOYMENT'])

# Then I should stop the servers
  @runner.behavior(:stop_all)

# Then I should set a variation for connecting to shared database host
  @runner.set_var(:set_master_db_dnsname)

# When I launch the "Load Balancer" servers
  @runner.behavior(:launch_set, "Load Balancer")

# Then I should wait for the state of "Load Balancer" servers to be "operational"
  @runner.behavior(:wait_for_set, "Load Balancer", "operational")

# Then I should set a variation LB_HOSTNAME
  @runner.set_var(:set_lb_hostname)

# When I launch the "App Server" servers
  @runner.behavior(:launch_set, "App Server")

# Then I should wait for the state of "App Server" servers to be "operational"
  @runner.behavior(:wait_for_set, "App Server", "operational")

# Then I should run unified application checks on app servers
  @runner.behavior(:run_unified_application_checks, @runner.send(:app_servers))

# Then I should run frontend checks
  @runner.behavior(:frontend_checks)

# Then I should run log rotation checks
  @runner.behavior(:log_rotation_checks)

## TODO?
## When I restart apache
#
#
## Then apache status should be good
#
#
# Then I should test reboot operations on the deployment
  @runner.behavior(:run_reboot_operations)
