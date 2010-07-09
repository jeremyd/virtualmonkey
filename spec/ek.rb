require 'rubygems'
require "ruby-debug"
require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Messing with spec" do
  before(:all) do
    raise "for this spec to run, you must have a mysql deployment nickname in $DEPLOYMENT variable" unless ENV['DEPLOYMENT']
    @runner = VirtualMonkey::MysqlRunner.new(ENV['DEPLOYMENT'])
    @runner.lookup_scripts
    @runner.lineage='testlineage3049'
    @runner.stripe_count=1
#    @runner.set_variation_lineage
    @master = @runner.servers.first
    @master.start
    @master.wait_for_operational_with_dns
    @master.settings
    puts "master is #{@master.dns_name}"
#    @runner.config_master_from_scratch(master)
#    @runner.setup_dns

  end
  it "wait for master snapshot to complete - no pending snapshots for master lineage" do
# take the lineage name, find all snapshots and verify that none are in the pending state.
    @runner.run_script("backup", @master)
    @runner.wait_for_snapshots
debugger
  end
end
