require 'rubygems'
require 'rest_connection'
require 'virtualmonkey'

Then /I should run unified application checks/ do
  @runner.run_unified_application_checks
end
