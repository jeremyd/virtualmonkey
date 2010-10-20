module VirtualMonkey
  module Simple

# TODO - we do not know what the RS_INSTANCE_ID available to the testing.
# For now we are checking at a high level that the services are working
# and then assume that the config file changes done during start are
# correct for the new instance data.
#
    def perform_start_stop_operations
      # Save configuration files for comparison after starting
      # Stop the servers
      # Verify all stopped
      # Start the servers
      # Verify operational
      run_simple_checks
    end

    # Copy configuration files into some location for usage after start
    def save_configuration_files
      puts "Saving config files"
    end

    # Diff the new config file with the saved one and check that the only
    # line that is different is the one that has the mydestination change
    def test_mail_config(server)
      puts "Mail config check TODO"
    end
    
    # Diff the new config file with the saved one and check that the only
    # line that is different is the one that has the hostname change
    def test_syslog_config(server)
      puts "syslog config check TODO"
    end
    
    def run_simple_checks
      run_on.each do |server| 
        run_simple_check(server)
      end
    end
    
    # this is where ALL the generic application server checks live, this could get rather long but for now it's a single method with a sequence of checks
    def run_simple_check(server)
      test_mail_config(server)
      test_syslog_config(server)
    end
  end
end
