module VirtualMonkey
  module Frontend
  
    # returns an Array of the Front End servers in the deployment
    def fe_servers
      res = @servers.select { |s| s.nickname =~ /Front End/ || s.nickname =~ /FrontEnd/ || s.nickname =~ /Apache with HAproxy/ || s.nickname =~ /RightScale Load Balancer/ }
      raise "FATAL: No frontend servers found" unless res
      res
    end

    # returns String with all the private dns of the Front End servers
    # used for setting the LB_HOSTNAME input.
    def get_lb_hostname_input
      lb_hostname_input = "text:"
      fe_servers.each do |fe|
        lb_hostname_input << fe.settings['private-dns-name'] + " " 
      end
      lb_hostname_input
    end

    def frontend_checks
      detect_os

      run_unified_application_checks(fe_servers, 80)

      # check that all application servers exist in the haproxy config file on all fe_servers
      server_ips = Array.new
      app_servers.each { |app| server_ips << app['private-ip-address'] }
      fe_servers.each do |fe|
        fe.settings
        haproxy_config = fe.spot_check_command('flock -n /home/haproxy/rightscale_lb.cfg -c "cat /home/haproxy/rightscale_lb.cfg | grep server"')
        puts "INFO: flock status was #{haproxy_config[:status]}"
        server_ips.each do |ip|
          if haproxy_config.to_s.include?(ip) == false
            puts haproxy_config[:output]
            raise "FATAL: haproxy config did not contain server ip #{ip}"
          end
        end
      end

      # restart haproxy and check that it succeeds
      fe_servers.each_with_index do |server,i|
        response = server.spot_check_command?('service haproxy stop')
        raise "Haproxy stop command failed" unless response

        stopped = false
        count = 0
        until response || count > 3 do
          response = server.spot_check_command(server.haproxy_check)
          stopped = response.include?("not running")
          break if stopped
          count += 1
          sleep 10
        end

        response = server.spot_check_command?('service haproxy start')
        raise "Haproxy start failed" unless response
      end

      # restart apache and check that it succeeds
      statuses = Array.new
      fe_servers.each { |s| statuses << s.run_executable(@scripts_to_run['apache_restart']) }
      statuses.each { |status| status.wait_for_completed }
      fe_servers.each_with_index do |server,i|
        response = nil
        count = 0
        until response || count > 3 do
          response = server.spot_check_command?(server.apache_check)
          break if response	
          count += 1
          sleep 10
        end
        raise "Apache status failed" unless response
      end
      
    end

    def cross_connect_frontends
      statuses = Array.new 
      options = { :LB_HOSTNAME => get_lb_hostname_input }
      fe_servers.each { |s| statuses << s.run_executable(@scripts_to_run['connect'], options) }
      statuses.each_with_index { |s,i| s.wait_for_completed }
    end

    def lookup_scripts
      @scripts_to_run = {}
      st = ServerTemplate.find(fe_servers.first.server_template_href)
      @scripts_to_run['connect'] = st.executables.detect { |ex| ex.name =~  /LB [app|mongrels]+ to HA proxy connect/i }
      @scripts_to_run['apache_restart'] = st.executables.detect { |ex| ex.name =~  /WEB apache \(re\)start v2/i }
    end 


    # Run spot checks for FE servers in the deployment
    def run_fe_tests
    end

    # Special startup sequence for an FE deployment
    def startup
    end

  end
end
