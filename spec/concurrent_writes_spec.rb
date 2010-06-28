require File.join(File.dirname(__FILE__), "spec_helper")
require 'ruby-debug'

describe SharedDns, "Using sdb to store shared resources" do
  it "should perform concurrent reads and writes" do
    unique_record = "blah#{rand(10000000)}"
    
    reservations = Array.new
    18.times do |i|
      reservations[i] = SharedDns.new
    end

    reservations[0].release_all

    mythreads = Array.new
    reservations.each do |x|
      mythreads << Thread.new do
        x.reserve_dns
# all reservations should succeed
        x.should_not == false
        puts  "reserved #{x.reservation}"
        STDOUT.flush
      end
    end
  end
end
