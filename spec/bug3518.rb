require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "bug #3518" do
  before(:all) do
    raise "for this spec to run, you must have a mysql deployment nickname in $DEPLOYMENT variable" unless ENV['DEPLOYMENT']
    @runner = VirtualMonkey::MysqlRunner.new(ENV['DEPLOYMENT'])
  end
  it "disables binlogs on the old master after promote" do
    @runner.run_promotion_operations
    oldmaster = @runner.servers.last 
    oldmaster.settings
    puts "oldmaster is #{oldmaster.dns_name}"
  end
end
