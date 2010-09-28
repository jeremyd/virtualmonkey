require "rubygems"
require "right_aws"

module VirtualMonkey
  class ELBRunner
    include VirtualMonkey::DeploymentRunner
    include VirtualMonkey::Application
    include VirtualMonkey::UnifiedApplication
    
    ELB_PORT = 80
    ELB_PORT_FORWARD = 8000
    ELB_PREFIX = "MONKEY-TEST-ELB"
    
    AWS_ID = "you"
    AWS_KEY = "wish"
    
    # Hardcoded to ELBs created in dash for now.
    DNS = {
      "1" => "MONKEY-TEST-ELB-500034796.us-east-1.elb.amazonaws.com",
      "2" => "monkey-test-elb-2265692.us-west-1.elb.amazonaws.com",
      "3" => "monkey-test-elb-1494529434.eu-west-1.elb.amazonaws.com",
      "4" => "monkey-test-elb-498965605.ap-southeast-1.elb.amazonaws.com"
    }
    
    def initialize(args)
      super(args)
      @elb = RightAws::ElbInterface.new(AWS_ID, AWS_KEY)
      @elb_name = "#{ELB_PREFIX}-#{rand(1000000)}"
    end
    
    # sets ELB_NAME on the deployment using hardcoded name
    def set_elb_name
      @deployment.set_input("ELB_NAME", "text:#{@elb_name}")
    end
    
    # The ELB should be serving up the unified app after boot
    def run_elb_checks
      run_unified_application_check(elb_href, ELB_PORT)
    end
    
    # Check if :all or :none of the app servers are registered
    def elb_registration_check(type)
      details = @elb.describe_load_balancers("MONKEY-TEST-ELB")
      instances = details.first[:instances]
      case type
      when :all
        @servers.each do |server|
          server.settings
          aws_id = server["aws-id"]
          raise "ERROR: Did not find aws id for #{aws_id}. ID list: #{instances.inspect}" unless instances.include?(aws_id)
        end
      when :none
        raise "ERROR: found registered instances when there should be none. ID list: #{instances.inspect}" unless instances.empty?
      else
        raise "ERROR: only check types of :none and :all are currently supported" 
      end
    end
    
    # Disconnect everyone
    def elb_disconnect_all
      @servers.each do |server|
        disconnect_server(server)
      end
    end
    
    # Used to make sure everyone is disconnected
    def elb_response_code(elb_expected_code)
      test_http_response(elb_expected_code, elb_href, ELB_PORT)
    end
    
    # Grab the scripts we plan to excersize
    def lookup_scripts
      @scripts_to_run = {}
      server = @servers.first
      server.settings 
      st = ServerTemplate.find(server.server_template_href)
      @scripts_to_run['connect'] = st.executables.detect { |ex| ex.name =~  /ELB connect/i }
      @scripts_to_run['disconnect'] = st.executables.detect { |ex| ex.name =~  /ELB disconnect/i }
      # @scripts_to_run['apache_restart'] = st.executables.detect { |ex| ex.name =~  /WEB apache \(re\)start v2/i }
    end 
    
    # This is really just a PHP server check. relocate?
    def log_rotation_checks
      detect_os
      
      # this works for php
      app_servers.each do |server|
        server.settings
        force_log_rotation(server)
        log_check(server,"/mnt/log/#{server.apache_str}/access.log.1")
      end
    end
    
    def create_elb
      @elb.create_load_balancer(@elb_name,
                                 ['us-east-1a'],  #only one az.  make sure test launches server in other A.Z.
                                 [ { :protocol => :http, :load_balancer_port => ELB_PORT,  :instance_port => ELB_PORT_FORWARD } ] )
    end
    
    def destroy_elb
      @elb.delete_load_balancer(@elb_name)
    end
    
  private 
   
    # How do we find our ELB?
    def elb_href
      cloud_id = get_cloud_id
      "http:\/\/#{DNS[cloud_id]}"
    end
    
    # What cloud is the first server in?
    def get_cloud_id
      server = @servers.first
      server.settings 
      server.cloud_id
    end
    
    # run the ELB connect script
    def connect_server(server)
      run_script('connect', server)
    end

    # run the ELB disconnect script
    def disconnect_server(server)
      run_script('disconnect', server)
    end
    
   end
end