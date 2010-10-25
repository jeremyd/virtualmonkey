module VirtualMonkey
  module DeploymentRunner
    attr_accessor :deployment, :servers
    attr_accessor :scripts_to_run
    
    def initialize(deployment)
      @deployment = Deployment.find_by_nickname_speed(deployment).first
      raise "Fatal: Could not find a deployment named #{deployment}" unless @deployment
      @servers = @deployment.servers_no_reload
      lookup_scripts
    end

    def lookup_scripts
      puts "WARNING: lookup_scripts is undefined, this must be set in mixin classes"
    end

    def s_one
      @servers[0]
    end

    def s_two
      @servers[1]
    end

    def s_three
      @servers[2]
    end

    def s_four
      @servers[3]
    end

    # Launch all servers in the deployment.
    def launch_all
      @servers.each { |s| s.start }
    end

    # sets the MASTER_DB_DNSNAME to this machine's ip address
    def set_master_db_dnsname
      the_name = get_tester_ip_addr
      @deployment.set_input("MASTER_DB_DNSNAME", the_name) 
      @deployment.set_input("DB_HOST_NAME", the_name) 
    end

    # Helper method, performs selection of a subset of servers to operate on based on the server's nicknames.
    # * nickname_substr<~String> - regex compatible string to match
    def select_set(nickname_substr)
      @servers.select { |s| s.nickname =~ /#{nickname_substr}/ }
    end

    # Launch server(s) that match nickname_substr
    # * nickname_substr<~String> - regex compatible string to match
    def launch_set(nickname_substr)
      set = select_set(nickname_substr)  
      set.each { |server| server.start }
    end

    # Re-Launch all server
    def relaunch_all
      @servers.each { |s| s.relaunch }
    end

    # un-set all tags on all servers in the deployment
    def unset_all_tags
      @deployment.servers_no_reload.each do |s|
        # can't unset ALL tags, so we must set a bogus one
        s.tags = [{"name"=>"removeme:now=1"}]
        s.save
      end
    end

    # Wait for server(s) matching nickname_substr to enter state
    # * nickname_substr<~String> - regex compatible string to match
    # * state<~String> - state to wait for, eg. operational
    def wait_for_set(nickname_substr, state)
      set = select_set(nickname_substr)  
      state_wait(set, state)
    end

    # Wait for server(s) matching nickname_substr to enter state
    # * servers<~Array> - Array of Servers to wait on
    # * state<~String> - state to wait for, eg. operational
    def wait_for_servers(servers, state)
      state_wait(set, state)
    end

    # Helper method, waits for state on a set of servers.
    # * set<~Array> of servers to operate on
    # * state<~String> state to wait for
    def state_wait(set, state)
      # do a special wait, if waiting for operational (for dns)
      if state == "operational"
        set.each { |server| server.wait_for_operational_with_dns }
      else
        set.each { |server| server.wait_for_state(state) }
      end
    end
    
    # Wait for all server(s) to enter state.
    # * state<~String> - state to wait for, eg. operational
    def wait_for_all(state)
      state_wait(@servers, state)
    end

    def start_ebs_all(wait=true)
      @servers.each { |s| s.start_ebs }
      wait_for_all("operational") if wait
      @servers.each { |s| 
        s.dns_name = nil 
        s.private_dns_name = nil
        }
    end

    def stop_ebs_all(wait=true)
      @servers.each { |s| s.stop_ebs }
      wait_for_all("stopped") if wait
      @servers.each { |s| 
        s.dns_name = nil 
        s.private_dns_name = nil
        }
    end

    def stop_all(wait=true)
      @servers.each { |s| s.stop }
      wait_for_all("stopped") if wait
      @servers.each { |s| 
        s.dns_name = nil 
        s.private_dns_name = nil
        }
    end

    def reboot_all
      wait_for_reboot = true
      @servers.each do |s| 
        s.reboot(wait_for_reboot) 
      end
      @servers.each do |s| 
        s.wait_for_state("operational")
      end
    end

    # Run a script on server in the deployment
    # * server<~Server> the server to run the script on
    # * friendly_name<~String> string lookup for Hash @scripts_to_run.  @scripts_to_run must be a Hash containing an Executable with this key.
    def run_script(friendly_name, server)
      audit = server.run_executable(@scripts_to_run[friendly_name])
      audit.wait_for_completed
    end

    
    # Detect operating system on each server and stuff the corresponding values for platform into the servers params (for temp storage only)
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
    
    # Log rotation
    def force_log_rotation(server)
      response = server.spot_check_command?('logrotate -f /etc/logrotate.conf')
      raise "Logrotate restart failed" unless response
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

    # Checks that monitoring is enabled on all servers in the deployment.  Will raise an error if monitoring is not enabled.
    def check_monitoring
      @servers.each do |server|
        server.settings
        response = nil
        count = 0
        until response || count > 20 do
          begin
            response = server.monitoring
          rescue
            response = nil
            count += 1
            sleep 30
          end
        end
        raise "Fatal: Failed to verify that monitoring is operational" unless response
      end
    end



# TODO - we do not know what the RS_INSTANCE_ID available to the testing.
# For now we are checking at a high level that the services are working
# and then assume that the config file changes done during start are
# correct for the new instance data.
#
    def perform_start_stop_operations
      detect_os
      s=@servers.first
      # Save configuration files for comparison after starting
      save_configuration_files(s)
      # Stop the servers
      stop_ebs_all
      # Verify all stopped
      # Start the servers
      start_ebs_all(true)
#      Do this for all? Or just the one?
#      @servers.each { |server| server.wait_for_operational_with_dns }
      s=@servers.first
      s.wait_for_operational_with_dns
      # Verify operational
      run_simple_check(s)
    end

# TODO there will be other files that need compares et al.  Create a list
# of them and abstarct the tests
    # Copy configuration files into some location for usage after start
    def save_configuration_files(server)
      puts "Saving config files"
      server.spot_check_command('mkdir -p /root/start_stop_backup')
      server.spot_check_command('cp /etc/postfix/main.cf /root/start_stop_backup/.')
      server.spot_check_command('cp /etc/syslog-ng/syslog-ng.conf /root/start_stop_backup/.')
    end

    # Diff the new config file with the saved one and check that the only
    # line that is different is the one that has the mydestination change
    def test_mail_config(server)
      res = server.spot_check_command('diff /etc/postfix/main.cf /root/start_stop_backup/main.cf')
# This is lame - assuming if the file is modified then it's okay
        raise "ERROR: postfix main.cf configuration file did not change when restarted" unless res
    end
    
    def test_syslog_config(server)
      res = server.spot_check_command('diff /etc/syslog-ng/syslog-ng.conf /root/start_stop_backup/syslog-ng.conf')
# This is lame - assuming if the file is modified then it's okay
      raise "ERROR: syslog-ng configuration file did not change when restarted" unless res
    end
    
    def run_simple_checks
      @servers.each { |s| run_simple_check(s) }
    end
    
    # this is where ALL the generic application server checks live, this could get rather long but for now it's a single method with a sequence of checks
    def run_simple_check(server)
      test_mail_config(server)
      test_syslog_config(server)
    end
  end
end
