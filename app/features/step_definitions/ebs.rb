require "rubygems"
require File.expand_path(File.join(File.dirname(__FILE__) , '..','..','..','spec','spec_helper'))

Given /A EBS Toolbox deployment/ do
  raise "FATAL:  Please set the environment variable $DEPLOYMENT" unless ENV['DEPLOYMENT']

  @runner = VirtualMonkey::EBSRunner.new(ENV['DEPLOYMENT'])
  @runner.lookup_scripts
end

Then /^I should set a variation EBS volume size "([^\"]*)"$/ do |size|
  @runner.set_variation_volume_size(size)
end

Then /^I should set a variation EBS mount point "([^\"]*)"$/ do |mnt|
  @runner.set_variation_mount_point(mnt)
end

Then /^I should create a new EBS stripe with data$/ do
  @runner.create_stripe_with_data
end

Then /^I should test the backup script operations$/ do
  @runner.test_backup_script_operations
end
#
Then /^I should backup the volume$/ do
  @runner.create_backup(@servers.first)
end
#
Then /^I should restore the volume$/ do
  @runner.restore_from_backup(@servers.last)
end
#
Then /^I should verify EBS volume is populated$/ do
  @runner.verify_volume_data(@servers.last)
end
#
When /^I terminate the server$/ do
  @runner.terminate_server(@servers.last)
end
#
Then /^I should see the server stopped$/ do
  @runner.verify_server_stopped(@servers.last)
end
