require File.expand_path(File.join(File.dirname(__FILE__) , '..','..','spec','spec_helper'))

Then /^I should cross connect the frontends/ do
  @runner.cross_connect_frontends
end

Then /^I should set a variation MASTER_DB_DNSNAME/ do
  @runner.set_master_db_dnsname
end

Then /^I should set a variation LB_HOSTNAME/ do
  @runner.set_lb_hostname
end