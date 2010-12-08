#@lb_test
#
#Feature: PHP Server Templates
#  Tests the PHP servers
#
#Scenario: PHP server test
#
# Given A frontend with application servers deployment
  @runner = VirtualMonkey::FeAppRunner.new(ENV['DEPLOYMENT'])
  @runner.behavior(:lookup_scripts)

# Then I should stop the servers
  @runner.behavior(:stop_all)

# Then I should set a variation for connecting to shared database host
  @runner.behavior(:set_master_db_dnsname)

# When I launch the "Front End" servers
  @runner.behavior(:launch_set, "Front End")

# Then I should wait for the state of "Front End" servers to be "booting"
  @runner.behavior(:wait_for_set, "Front End", "booting")

# Then I should wait for the state of "Front End" servers to be "operational"
  @runner.behavior(:wait_for_set, "Front End", "operational")

# Then I should set a variation LB_HOSTNAME
  @runner.behavior(:set_lb_hostname)

# When I launch the "App Server" servers
  @runner.behavior(:launch_set, "App Server")

# Then I should wait for the state of "App Server" servers to be "booting"
  @runner.behavior(:wait_for_set, "App Server", "booting")

# Then I should wait for the state of "App Server" servers to be "operational"
  @runner.behavior(:wait_for_set, "App Server", "operational")

# Then I should cross connect the frontends
  @runner.behavior(:cross_connect_frontends)

# Then I should run unified application checks
  @runner.behavior(:run_unified_application_checks)

# Then I should run frontend checks
  @runner.behavior(:frontend_checks)

# Then I should run log rotation checks
  @runner.behavior(:log_rotation_checks)

# Then I should test reboot operations on the deployment
  @runner.behavior(:run_reboot_operations)

# Then I should check that monitoring is enabled
  @runner.behavior(:check_monitoring)
