require 'rubygems'
require "ruby-debug"
require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Messing with spec" do
  before(:all) do
    raise "for this spec to run, you must have a mysql deployment nickname in $DEPLOYMENT variable" unless ENV['DEPLOYMENT']
    @runner = VirtualMonkey::MysqlRunner.new(ENV['DEPLOYMENT'])
    @runner
    @runner.lookup_scripts
    @snapshot_lineage_prefix='testlineage3049'
#    @runner.setup_dns

  end
  it "wait for master snapshot to complete - no pending snapshots for master lineage" do
# take the lineage name, find all snapshots and verify that none are in the pending state.
snapshots =Ec2EbsSnapshot.find_by_cloud_id(3).select { |n| n.nickname =~ /#{@snapshot_lineage_prefix}.*$/ }
status= snapshots.map &:aws_status
puts status.join ","
puts "we got completed snapshots" if status.include?("completed") 
puts "we got pending snapshots" if status.include?("pending") 
debugger
puts x
  end
end
