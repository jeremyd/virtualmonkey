module VirtualMonkey
  module ApplicationFrontend
    include VirtualMonkey::Application
    include VirtualMonkey::Frontend
    include VirtualMonkey::UnifiedApplication
    
    # a custom startup sequence is required for fe/app deployments (inputs workaround)
    def startup_sequence
      fe_servers.each { |s| s.start }
      fe_servers.each { |s| s.wait_for_operational_with_dns }
      
      set_lb_hostname

      app_servers.each { |s| s.start }
      app_servers.each { |s| s.wait_for_operational_with_dns }
    end

    def run_reboot_operations
      reboot_all
      # This sleep is for waiting for the slave to catch up to the master since they both reboot at once
      sleep 120
      run_reboot_checks
    end

    def run_reboot_checks
      run_unified_application_checks(fe_servers, 80)
#      run_unified_application_checks
    end
    
    def log_rotation_checks
      # this works for php, TODO: rails
      #app_servers.each do |server|
      #  force_log_rotation(server)
      #  log_check(server,"/mnt/log/#{server.apache_str}/access.log.1")
      #end

      fe_servers.each do |server|
        force_log_rotation(server)
        log_check(server, "/mnt/log/#{server.apache_str}/haproxy.log.1")
      end
    end
        
  end
end
