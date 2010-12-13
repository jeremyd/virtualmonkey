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
      behavior(:reboot_all, true)
      behavior(:run_reboot_checks)
    end

    def run_reboot_checks
      behavior(:run_unified_application_checks, fe_servers, 80)
      behavior(:run_unified_application_checks, app_servers)
    end
    
    def log_rotation_checks
      # this works for php, TODO: rails
      #app_servers.each do |server|
      #  force_log_rotation(server)
      #  log_check(server,"/mnt/log/#{server.apache_str}/access.log.1")
      #end

      fe_servers.each do |server|
        behavior(:force_log_rotation, server)
        behavior(:log_check, server, "/mnt/log/#{server.apache_str}/haproxy.log.1")
      end
    end
    
  end
end
