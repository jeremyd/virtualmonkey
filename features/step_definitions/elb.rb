When /^I create EC2 Elastic Load Balancer$/ do 
  @runner.create_elb
end

Then /^I should set a variation ELB_NAME$/ do
  @runner.set_elb_name
end

Then /^I should run EC2 Elastic Load Balancer unified_app checks$/ do 
  @runner.run_elb_checks
end

When /^I disconnect all servers from ELB$/ do
  @runner.elb_disconnect_all
end

Then /^I should get a http code (\d+) from ELB$/ do |code|
  @runner.elb_response_code(code)
end

Then /^all instances should be registered with ELB$/ do
  @runner.elb_registration_check(:all)
end

Then /^no instances should be registered with ELB$/ do
  @runner.elb_registration_check(:none)
end

When /^I delete EC2 Elastic Load Balancer$/ do
  @runner.destroy_elb
end

Then /^the servers should strand with "([^"]*)"$/ do |arg1|
  pending # express the regexp above with the code you wish you had
end