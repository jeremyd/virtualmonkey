Then /I should run mysql checks/ do
  @runner.run_checks
end

Then /I should set a variation backup prefix/ do
  @runner.set_variation_backup_prefix
end

Then /I should set a variation bucket/ do
  @runner.set_variation_bucket
end

Then /I should test promotion operations on the deployment/ do
  @runner.run_promotion_operations
end

Then /I should set a chef variation lineage/ do
  @runner.set_variation_lineage("chef")
end

Then /I should set a variation lineage/ do
  @runner.set_variation_lineage
end

Then /^I should set a variation stripe count of "([^\"]*)"$/ do |stripe|
  @runner.set_variation_stripe_count(stripe)
end

Then /^I should set a variation MySQL DNS/ do
  @runner.setup_dns
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

Then /^I should release the dns records for use with other deployments$/ do
  @runner.release_dns
end

Then /^I should setup master dns to point at server "([^\"]*)"$/ do |server_index|
  @runner.set_master_dns(server_index)
end
