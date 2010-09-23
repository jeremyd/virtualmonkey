require File.expand_path(File.join(File.dirname(__FILE__) , '..','..','spec','spec_helper'))

Given /^A simple deployment/ do
  raise "FATAL:  Please set the environment variable $DEPLOYMENT" unless ENV['DEPLOYMENT']
  @runner = VirtualMonkey::SimpleRunner.new(ENV['DEPLOYMENT'])
end

Given /^A LAMP deployment/ do
  raise "FATAL:  Please set the environment variable $DEPLOYMENT" unless ENV['DEPLOYMENT']
  @runner = VirtualMonkey::LampRunner.new(ENV['DEPLOYMENT'])
end

Given /^An ELB Test deployment/ do
  raise "FATAL:  Please set the environment variable $DEPLOYMENT" unless ENV['DEPLOYMENT']
  @runner = VirtualMonkey::ELBRunner.new(ENV['DEPLOYMENT'])
  @runner.lookup_scripts
end

Given /^A PHP Chef deployment/ do
  raise "FATAL:  Please set the environment variable $DEPLOYMENT" unless ENV['DEPLOYMENT']
  @runner = VirtualMonkey::PhpChefRunner.new(ENV['DEPLOYMENT'])
end

Given /A Rails AIO Developer Chef deployment/ do
  raise "FATAL:  Please set the environment variable $DEPLOYMENT" unless ENV['DEPLOYMENT']
  @runner = VirtualMonkey::RailsAioDeveloperChefRunner.new(ENV['DEPLOYMENT'])
end

Given /^A PHP AIO Trial Chef deployment/ do
  raise "FATAL:  Please set the environment variable $DEPLOYMENT" unless ENV['DEPLOYMENT']
  @runner = VirtualMonkey::PhpAioTrialChefRunner.new(ENV['DEPLOYMENT'])
end

Given /^A MySQL Toolbox deployment$/ do
  raise "FATAL:  Please set the environment variable $DEPLOYMENT" unless ENV['DEPLOYMENT']

  @runner = VirtualMonkey::MysqlToolboxRunner.new(ENV['DEPLOYMENT'])
  @runner.lookup_scripts
end

Given /A MySQL deployment/ do
  raise "FATAL:  Please set the environment variable $DEPLOYMENT" unless ENV['DEPLOYMENT']

  @runner = VirtualMonkey::MysqlRunner.new(ENV['DEPLOYMENT'])
  @runner.lookup_scripts
end

Given /A frontend with application servers deployment/ do
  raise "FATAL:  Please set the environment variable $DEPLOYMENT" unless ENV['DEPLOYMENT']

# EXPERIMENTAL
# sleep here to delay the run of the cucumber initial calls to the api. (be nice)
  num = rand(120)
  puts "delaying start of test by #{num} seconds"
  sleep num
  @runner = VirtualMonkey::FeAppRunner.new(ENV['DEPLOYMENT'])
  @runner.lookup_scripts
end

Then /I will fail/ do
  raise "Test failure simulation!"
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

Then /I should check that monitoring is enabled$/ do
  @runner.check_monitoring
end
