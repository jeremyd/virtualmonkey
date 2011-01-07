require "rubygems"
require "right_aws"

module VirtualMonkey
  class PatchRunner
    include VirtualMonkey::DeploymentRunner
    
    
    # It's not that I'm a Java fundamentalist; I merely believe that mortals should
    # not be calling the following methods directly. Instead, they should use the
    # TestCaseInterface methods (behavior, verify, probe) to access these functions.
    # Trust me, I know what's good for you. -- Tim R.
    private

    def initialize(args)
      super(args)
    end
    
    # Grab the scripts we plan to excersize
    def lookup_scripts
      scripts = [
                 [ 'test_patch', 'TEST' ]
               ]
      server = @servers.first
      server.settings 
      st = ServerTemplate.find(server.server_template_href)
      lookup_scripts_table(st,scripts)
    end 

    def set_user_data(value)
        @servers.each do |server|
	    server.settings
	    server.ec2_user_data = value
	    server.save
        end
    end 
    
    # run the patch test script
    def run_patch_test
	@servers.each do |server|	
	  run_script('test_patch', server)
	end
    end

   end
end
