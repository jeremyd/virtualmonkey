require 'timeout'
require 'spec'

module VirtualMonkey
  module VirtualMonkey::ApplicationFrontend

    # returns an Array of the App Servers in the deployment
    def app_servers
      @servers.select { |s| s.nickname =~ /App Server/ }
    end
    
    # sets the MASTER_DB_DNSNAME to this machine's ip address
    def set_master_db_dnsname
      the_name = get_tester_ip_addr
      @deployment.set_input("MASTER_DB_DNSNAME", the_name) 
      @deployment.set_input("DB_HOST_NAME", the_name) 
    end

    # returns an Array of the Front End servers in the deployment
    def fe_servers
      @servers.select { |s| s.nickname =~ /Front End/ || s.nickname =~ /FrontEnd/ }
    end

    # sets LB_HOSTNAME on the deployment using the private dns of the fe_servers
    def set_lb_hostname
      @deployment.set_input("LB_HOSTNAME", get_lb_hostname_input)
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

    # returns true if the http response contains the expected_string
    # * url<~String> url to perform http request
    # * expected_string<~String> regex compatible string used to match against the response output
    def test_http_response(expected_string, url, port)
      cmd = "curl -s #{url} 2> /dev/null "
      puts cmd
      timeout=300
      begin
        status = Timeout::timeout(timeout) do
          while true
            response = `#{cmd}` 
            break if response.include?(expected_string)
            puts "Retrying..."
            sleep 5
          end
        end
      rescue Timeout::Error => e
        raise "ERROR: Query failed after #{timeout/60} minutes."
      end
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
        server_ips.each { |ip|  haproxy_config.to_s.include?(ip).should == true }
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

    # a custom startup sequence is required for fe/app deployments (inputs workaround)
    def startup_sequence
      fe_servers.each { |s| s.start }
      fe_servers.each { |s| s.wait_for_operational_with_dns }
      
      set_lb_hostname

      app_servers.each { |s| s.start }
      app_servers.each { |s| s.wait_for_operational_with_dns }
    end

    def force_log_rotation(server)
      response = server.spot_check_command?('logrotate -f /etc/logrotate.conf')
      raise "Logrotate restart failed" unless response
    end

    def run_reboot_operations
      reboot_all
      # This sleep is for waiting for the slave to catch up to the master since they both reboot at once
      sleep 120
      run_reboot_checks
    end

    def run_reboot_checks
      run_unified_application_checks(fe_servers, 80)
      run_unified_application_checks
    end

    def log_check(server, logfile)
      response = nil
      count = 0
      until response || count > 3 do
        response = server.spot_check_command?("test -f #{logfile}")
        break if response
        count += 1
        sleep 10
      end
      raise "Log file does not exist: #{logfile}" unless response
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

    # detect operating system on each server and stuff the corresponding values for platform into the servers params (for temp storage only)
    def detect_os
      @server_os = Array.new
      @servers.each do |server|
        if server.spot_check_command?("lsb_release -is | grep Ubuntu")
          puts "setting server to ubuntu"
          server.os = "ubuntu"
          server.apache_str = "apache2"
          server.apache_check = "apache2ctl status"
          server.haproxy_check = "service haproxy status"
        else
          puts "setting server to centos"
          server.os = "centos"
          server.apache_str = "httpd"
          server.apache_check = "service httpd status"
          server.haproxy_check = "service haproxy check"
        end
      end
    end

    def run_rails_demo_application_checks(run_on=@servers,port=80)
      run_on.each do |server|
        url_base = "#{server.dns_name}:#{port}"
        test_http_response("Mephisto", url_base, port) 
      end
    end

    # this is where ALL the generic application server checks live, this could get rather long but for now it's a single method with a sequence of checks
    def run_unified_application_checks(run_on=@servers, port=8000)
      run_on.each do |server| 
        url_base = "#{server.dns_name}:#{port}"
        test_http_response("html serving succeeded", "#{url_base}/index.html", port) 
        test_http_response("configuration=succeeded", "#{url_base}/appserver/", port) 
        test_http_response("I am in the db", "#{url_base}/dbread/", port) 
        test_http_response("hostname=", "#{url_base}/serverid/", port) 
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

    # Assumes the host machine is EC2, uses the meta-data to grab the IP address of this
    # 'tester server' eg. used for the input variation MASTER_DB_DNSNAME
    def get_tester_ip_addr
      if File.exists?("/var/spool/ec2/meta-data.rb")
        require "/var/spool/ec2/meta-data-cache" 
      else
        ENV['EC2_PUBLIC_HOSTNAME'] = "127.0.0.1"
      end
      my_ip_input = "text:" 
      my_ip_input += ENV['EC2_PUBLIC_HOSTNAME']
      my_ip_input
    end

    # Run spot checks for APP servers in the deployment
    def run_app_tests
    end

    # Run spot checks for FE servers in the deployment
    def run_fe_tests
    end

    # Special startup sequence for an FE+APP deployment
    def startup
    end

  end
end
