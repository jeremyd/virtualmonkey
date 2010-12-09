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
    
    AWS_ID = ENV['AWS_ACCESS_KEY_ID']
    AWS_KEY = ENV['AWS_SECRET_ACCESS_KEY']

    ELBS = { 1 => { 
                :endpoint => "https://elasticloadbalancing.us-east-1.amazonaws.com",
                :azs => [ "us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d" ]
                },
             2 => {
                :endpoint => "https://elasticloadbalancing.eu-west-1.amazonaws.com",
                :azs => [ "eu-west-1a", "eu-west-1b" ] 
                },
             3 => {
                :endpoint => "https://elasticloadbalancing.us-west-1.amazonaws.com",
                :azs => [ "us-west-1a", "us-west-1b" ] 
                },
             4 => {
                :endpoint => "https://elasticloadbalancing.ap-southeast-1.amazonaws.com",
                :azs => [ "ap-southeast-1a", "ap-southeast-1a" ] 
                }
          }
    
    # It's not that I'm a Java fundamentalist; I merely believe that mortals should
    # not be calling the following methods directly. Instead, they should use the
    # TestCaseInterface methods (behavior, verify, probe) to access these functions.
    # Trust me, I know what's good for you. -- Tim R.
    private

    def initialize(args)
      super(args)
      endpoint_url=ELBS[get_cloud_id][:endpoint]
puts "USING EP: #{endpoint_url}"
      @elb = RightAws::ElbInterface.new(AWS_ID, AWS_KEY, { :endpoint_url => endpoint_url } )
#      @elb_name = "#{ELB_PREFIX}-#{rand(1000000)}"
      @elb_name = @deployment.href.split(/\//).last
    end
    
    def retry_elb_fn(fn, *args)
      backoff = 60
      retry_loop = 0
      begin
        begin
          result = @elb.__send__(fn, *args)
          done = true
        rescue Exception => e
          if e.message =~ /Throttling/
            puts "Rescuing ELB error: #{e.message}"
            raise "FATAL: Exceeded ELB retry limit" unless retry_loop < 10
            sleep (rand(backoff))
            retry_loop += 1
          else
            raise e
          end
        end
      end while !done
      result
    end

    def set_elb_name
      @deployment.set_input("ELB_NAME", "text:#{@elb_name}")
    end
    
    # The ELB should be serving up the unified app after boot
    def run_elb_checks
      run_unified_application_check(elb_href, ELB_PORT)
    end
    
    # Check if :all or :none of the app servers are registered
    def elb_registration_check(type)
      details = retry_elb_fn("describe_load_balancers",@elb_name)
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
      scripts = [
                 [ 'connect', 'ELB connect' ],
                 [ 'disconnect', 'ELB disconnect' ]
               ]
#      @scripts_to_run = {}
      server = @servers.first
      server.settings 
      st = ServerTemplate.find(server.server_template_href)
      lookup_scripts_table(st,scripts)
#      @scripts_to_run['connect'] = st.executables.detect { |ex| ex.name =~  /ELB connect/i }
#      @scripts_to_run['disconnect'] = st.executables.detect { |ex| ex.name =~  /ELB disconnect/i }
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
      begin
        array = retry_elb_fn("describe_load_balancers",@elb_name)
      rescue Exception => e
        if e.message =~ /Cannot find Load Balancer/
          array = []
        else
          raise e
        end
      end
      if array.length == 1
        @elb_dns = array.first[:dns_name]
      else
        raise "ERROR: More than one ELB with name \"#{@elb_name}\" found." if array.length > 1
        az = ELBS[get_cloud_id][:azs]
puts "Using az: #{az}"
        @elb_dns = retry_elb_fn("create_load_balancer",@elb_name,
                                 az,
                                 [ { :protocol => :http, :load_balancer_port => ELB_PORT,  :instance_port => ELB_PORT_FORWARD } ] )
      end
    end
    
    def destroy_elb
      success = retry_elb_fn("delete_load_balancer",@elb_name)
      raise "ERROR: unable to delete ELB name=#{@elb_name}" unless success
    end
    
  private 
   
    def elb_href
      "http:\/\/#{@elb_dns}"
    end
    
    # What cloud is the first server in?
    def get_cloud_id
      case ENV['DEPLOYMENT']
      when /ec2-east/
        return 1
      when /ec2-eu/
        return 2
      when /ec2-west/
        return 3
      when /ec2-ap/
        return 4
      end
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
