#@base
#
#Feature: Base Server Test
#  Tests the base server functions
#
#Scenario: base server test
#
#  Given A simple deployment
  raise "FATAL:  Please set the environment variable $DEPLOYMENT" unless ENV['DEPLOYMENT']
  @runner = VirtualMonkey::SimpleRunner.new(ENV['DEPLOYMENT'])
#  Then I should stop the servers
  @runner.stop_all

#  Then I should launch all servers
  @runner.launch_all

#  Then I should wait for the state of "all" servers to be "operational"
    state = "operational"
    @runner.wait_for_all(state)
#  Then I should check that monitoring is enabled
  @runner.check_monitoring

#  Then I should reboot the servers
  @runner.reboot_all

#  Then I should wait for the state of "all" servers to be "operational"
    state = "operational"
    @runner.wait_for_all(state)

#  Then I should check that monitoring is enabled
  @runner.check_monitoring

