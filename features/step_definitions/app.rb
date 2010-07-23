require File.expand_path(File.join(File.dirname(__FILE__) , '..','..','spec','spec_helper'))

Then /I should run unified application checks/ do
  @runner.run_unified_application_checks
end
