require "rubygems"
#require "virtualmonkey"
require File.expand_path(File.join(File.dirname(__FILE__) , '..','..','..','spec','spec_helper'))

Given /A MySQL deployment/ do
  raise "FATAL:  Please set the environment variable $DEPLOYMENT" unless ENV['DEPLOYMENT']

  @runner = VirtualMonkey::MysqlRunner.new(ENV['DEPLOYMENT'])
  @runner.lookup_scripts
end

Given /A frontend with application servers deployment/ do
  raise "FATAL:  Please set the environment variable $DEPLOYMENT" unless ENV['DEPLOYMENT']

  @runner = VirtualMonkey::FeAppRunner.new(ENV['DEPLOYMENT'])
end

Then /I should test reboot operations on the deployment/ do
  @runner.run_reboot_operations
end

When /^I launch the "([^\"]*)" servers$/ do |server_set|
  @runner.launch_set(server_set)
end

Then /I should wait for the state of \"(.*)\" servers to be \"(.*)\"/ do |set,state|
  if set == "all"
    @runner.wait_for_all(state)
  else
    @runner.wait_for_set(set, state)
  end
end

Then /I should reboot the servers$/ do
  @runner.reboot_all
end

Then /I should stop the servers$/ do
  @runner.stop_all
end

Then /I should launch all servers$/ do
  @runner.launch_all
end
