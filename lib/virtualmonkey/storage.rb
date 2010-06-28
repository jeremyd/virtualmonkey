require 'rubygems'
require 'dm-core'
require 'fog'
require 'fog/credentials'

module VirtualMonkey
  module SharedResource
    def sdb
      @@sdb ||= Fog::AWS::SimpleDB.new(:aws_access_key_id => Fog.credentials[:aws_access_key_id], :aws_secret_access_key => Fog.credentials[:aws_secret_access_key])
      @@domain ||= "virtualmonkey_shared_resources"
      @@sdb
    end

    def create(tag)
      sdb.put_attributes(@@domain, self.resource_name, self.resource_name => tag)
    end

    def all
      result = self.sdb.get_attributes(@@domain, self.resource_name)
      result.body['Attributes'][resource_name]
    end

    def reject(value)
      result = self.all.reject { |r| r == value }
      self.sdb.put_attributes(@@domain, self.resource_name, {self.resource_name => result}, {:replace => [self.resource_name]})
    end

    def destroy_all
      self.sdb.delete_attributes(@@domain, self.resource_name)
    end
  end
end

class DeploymentSet
  extend VirtualMonkey::SharedResource
  def self.resource_name
    "deployment_sets"
  end
end

=begin
sqlitedb = File.join(File.dirname(__FILE__), "..", "..", "features", "shared.db")
puts "using #{sqlitedb}"
DataMapper.setup(:default, "sqlite3:#{sqlitedb}")

class DeploymentSet
  include DataMapper::Resource
  property :id, Serial
  property :tag, String
end

class TemplateSet
  include DataMapper::Resource
  property :id, Serial
  has n, :templates
end

class Template
  include DataMapper::Resource
  property :unique_id, Serial
  property :id, Integer
  belongs_to :template_set  
end
=end
