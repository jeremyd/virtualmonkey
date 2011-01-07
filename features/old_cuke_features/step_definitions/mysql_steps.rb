require File.expand_path(File.join(File.dirname(__FILE__) , '..','..','spec','spec_helper'))

Then /I should run mysql checks/ do
  @runner.run_checks
end

Then /I should run mysqlslap stress test/ do
  @runner.run_mysqlslap_check
end

Then /I should check that ulimit was set correctly/ do
  @runner.ulimit_check
end

#Then /I should set a variation backup prefix/ do
#  @runner.set_variation_backup_prefix
#end

Then /I should set a variation bucket/ do
  @runner.set_variation_bucket
end

Then /I should test promotion operations on the deployment/ do
  @runner.run_promotion_operations
end

#Then /I should set a chef variation lineage/ do
#  @runner.set_variation_lineage("chef")
#end

Then /I should set a variation lineage/ do
  @runner.set_variation_lineage
end

Then /^I should set a variation stripe count of "([^\"]*)"$/ do |stripe|
  @runner.set_variation_stripe_count(stripe)
end

# This is a hack - when we get rid of cucumber we can clean this up
# so we only have one DNS variation method
Then /^I should set a variation AWSDNS provider/ do
  @runner.setup_dns("virtualmonkey_awsdns")
end

Then /^I should set a variation DNS provider/ do
  @runner.setup_dns("virtualmonkey_dyndns")
end

Then /^I should set a variation MySQL DNS/ do
  @runner.setup_dns("virtualmonkey_shared_resources")
end

Then /^I should create the migration script/ do
  @runner.create_migration_script
end

Then /^I should migrate a new slave/ do
  @runner.migrate_slave
end

Then /^I should init a new v2 slave/ do
  @runner.launch_v2_slave
end

Then /^I should test the new v2 slave/ do
  @runner.run_checks
end

Then /^I should release the dns records for use with other deployments$/ do
  @runner.release_dns
end

#Then /^I should setup master dns to point at server "([^\"]*)"$/ do |server_index|
#  @runner.set_master_dns(server_index)
#end

Then /^I should create master from scratch$/ do
  @runner.create_master
end

Then /^I should run a restore using OPT_DB_RESTORE_TIMESTAMP_OVERRIDE$/ do
  @runner.run_restore_with_timestamp_override
end

