#@lamp_test
#
#Feature: LAMP Server Template Test
#  Tests the deployment
#
#Scenario: LAMP Server Template Test
#
# Given A LAMP deployment
  @runner = VirtualMonkey::LampRunner.new(ENV['DEPLOYMENT'])

# Then I should stop the servers
  @runner.behavior(:stop_all)

# Then I should launch all servers
  @runner.behavior(:launch_all)

# Then I should wait for the state of "all" servers to be "operational"
  @runner.behavior(:wait_for_all, "operational")

# Then I should run LAMP checks
  @runner.behavior(:run_lamp_checks)

# Then I should run mysql checks
  @runner.behavior(:run_checks)

## Then I should run mysqlslap stress test
#  @runner.behavior(:run_mysqlslap_check)
#
# Then I should check that ulimit was set correctly
  @runner.probe(".*", "su - mysql -s /bin/bash -c \"ulimit -n\"") { |s| s.to_i > 1024 }

# Then I should check that monitoring is enabled
  @runner.behavior(:check_monitoring)
