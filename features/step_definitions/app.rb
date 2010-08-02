require File.expand_path(File.join(File.dirname(__FILE__) , '..','..','spec','spec_helper'))

Then /I should run unified application checks/ do
  @runner.run_unified_application_checks
end

Then /I should run AIO rails demo application checks/ do
  @runner.run_rails_demo_application_checks
end

Then /^I should set a variation for connecting to shared database host/ do
  @runner.set_master_db_dnsname
end
