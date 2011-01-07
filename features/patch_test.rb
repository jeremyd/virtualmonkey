#@patch
#
# Feature: Base Server Test
#   Tests the base server functions
#
# Scenario: base server test
#
# Given A simple deployment
  @runner = VirtualMonkey::PatchRunner.new(ENV['DEPLOYMENT'])

# Then I should stop the servers
  @runner.behavior(:stop_all)

#uncomment this line to test patches from dev bucket
  @runner.behavior(:set_user_data, "RS_patch_url=http://s3.amazonaws.com/rightscale_rightlink_dev")

# Then I should launch all servers
  @runner.behavior(:launch_all)

# Then I should wait for the state of "all" servers to be "operational"
  @runner.behavior(:wait_for_all, "operational")

  @runner.behavior(:run_patch_test)

# Then I should reboot the servers
  @runner.behavior(:reboot_all)

  @runner.behavior(:run_patch_test)

# Then I should wait for the state of "all" servers to be "operational"
  @runner.behavior(:wait_for_all, "operational")


