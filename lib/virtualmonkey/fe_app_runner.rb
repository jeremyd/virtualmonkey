module VirtualMonkey
  class FeAppRunner
    include VirtualMonkey::DeploymentRunner
    include VirtualMonkey::ApplicationFrontend

#  This function is in the deployment_runner.rb
#  # sets the MASTER_DB_DNSNAME to this machine's ip address
#    def set_master_db_dnsname
#      the_name = get_tester_ip_addr
#      @deployment.set_input("MASTER_DB_DNSNAME", the_name) 
#      @deployment.set_input("DB_HOST_NAME", the_name) 
#    end

   end
end
