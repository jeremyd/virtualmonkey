require File.join(File.dirname(__FILE__), "spec_helper")
require 'ruby-debug'

class SharedResourceSpecTester
  extend VirtualMonkey::SharedSimpleExt
  include VirtualMonkey::SharedSimpleInc
  def self.resource_name
    "shared_resource_spec_tester"
  end
end

describe SharedResourceSpecTester, "Using sdb to store shared resources" do

  it "CRUD test" do
    SharedResourceSpecTester.destroy_all
    x = SharedResourceSpecTester.create(:tag => "sometag")
    y = SharedResourceSpecTester.create(:tag => "sometag2")
    x.tag.should == ["sometag"]
    x.destroy
    collection = SharedResourceSpecTester.all
    collection.first.tag.should == ["sometag2"]
  end

end
 
