require File.expand_path(File.join(File.dirname(__FILE__) , '..','..','spec','spec_helper'))

Given /A EBS Toolbox deployment/ do
  raise "FATAL:  Please set the environment variable $DEPLOYMENT" unless ENV['DEPLOYMENT']

  @runner = VirtualMonkey::EBSRunner.new(ENV['DEPLOYMENT'])
  @runner.lookup_scripts
end

Then /^I should set a variation volume size "([^\"]*)"$/ do |size|
  @runner.set_variation_volume_size(size)
end

Then /^I should set a variation mount point "([^\"]*)"$/ do |mnt|
  @runner.set_variation_mount_point(mnt)
end

Then /^I should create a new EBS stripe$/ do
  @runner.create_stripe
end

Then /^I should test the backup script operations$/ do
  @runner.test_backup_script_operations
end

Then /^I should backup the volume$/ do
  @runner.create_backup
end

Then /^I should test the restore operations$/ do
  @runner.test_restore
end

Then /^I should test the restore grow operations$/ do
  @runner.test_restore_grow
end
