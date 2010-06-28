require File.join(File.dirname(__FILE__), "spec_helper")
require 'ruby-debug'

describe DeploymentSet, "Using sdb to store shared resources" do

  it "CRUD test" do
    DeploymentSet.destroy_all
    DeploymentSet.create("blahblah123")
    DeploymentSet.create("1234")
    d = DeploymentSet.all
    d.include?("1234").should == true
    DeploymentSet.reject("1234")
    dew = DeploymentSet.all
    dew.include?("1234").should == false
  end

end
 
