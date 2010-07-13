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

Then /^I should create a new EBS stripe$/ do
  @runner.create_stripe
end

Then /^I should populate the EBS volume$/ do
  @runner.populate_volume
end



