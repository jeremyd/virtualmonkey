require "rubygems"
require "rest_connection"
require "net/ssh"
require 'virtualmonkey'

Then /^I should cross connect the frontends/ do
  @runner.cross_connect_frontends
end

Then /^I should set a variation MASTER_DB_DNSNAME/ do
  @runner.set_master_db_dnsname
end
