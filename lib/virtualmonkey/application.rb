require 'timeout'

module VirtualMonkey
  module Application

    # returns an Array of the App Servers in the deployment
    def app_servers
      @servers.select { |s| s.nickname =~ /App Server/ }
      raise "No app servers in deployment" if @servers.count == 0
    end
    
    # sets LB_HOSTNAME on the deployment using the private dns of the fe_servers
    def set_lb_hostname
      @deployment.set_input("LB_HOSTNAME", get_lb_hostname_input)
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
            puts response 
            break if response.include?(expected_string)
            puts "Retrying..."
            sleep 5
          end
        end
      rescue Timeout::Error => e
        raise "ERROR: Query failed after #{timeout/60} minutes."
      end
    end
    
    def run_rails_demo_application_checks(run_on=@servers,port=80)
      run_on.each do |server|
        url_base = "#{server.dns_name}:#{port}"
        test_http_response("Mephisto", url_base, port) 
      end
    end

    def lookup_scripts
      @scripts_to_run = {}
      st = ServerTemplate.find(@servers.first.server_template_href)
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

    # Special startup sequence for an APP deployment
    def startup
    end

  end
end
