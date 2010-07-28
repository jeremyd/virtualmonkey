require "rubygems"
#require "virtualmonkey"
require File.expand_path(File.join(File.dirname(__FILE__) , '..','..','..','spec','spec_helper'))

Given /^A MySQL Toolbox deployment$/ do
  raise "FATAL:  Please set the environment variable $DEPLOYMENT" unless ENV['DEPLOYMENT']

  @runner = VirtualMonkey::MysqlToolboxRunner.new(ENV['DEPLOYMENT'])
  @runner.setup_server_vars
  @runner.lookup_scripts
end

Given /^A Mysql deployment$/ do
  raise "FATAL:  Please set the environment variable $DEPLOYMENT" unless ENV['DEPLOYMENT']

  @runner = VirtualMonkey::MysqlRunner.new(ENV['DEPLOYMENT'])
  @runner.setup_server_vars
  @runner.lookup_scripts
end

Given /^A Mysql v1 deployment$/ do 
  raise "FATAL:  Please set the environment variable $DEPLOYMENT2" unless ENV['DEPLOYMENT2']
  @runner_v1 = VirtualMonkey::MysqlRunner.new(ENV['DEPLOYMENT2'])
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

Then /I should stop the v1 servers$/ do
  @runner_v1.stop_all
end

Then /I should launch all servers$/ do
  @runner.launch_all
end
