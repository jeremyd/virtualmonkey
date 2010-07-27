module VirtualMonkey
  module DeploymentRunner
    attr_accessor :deployment, :servers
    attr_accessor :scripts_to_run
    
    def initialize(deployment)
      @deployment = Deployment.find_by_nickname_speed(deployment).first
      raise "Fatal: Could not find a deployment named #{deployment}" unless @deployment
      @servers = @deployment.servers_no_reload
    end

    # Launch all servers in the deployment.
    def launch_all
      @servers.each { |s| s.start }
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

    def stop_all
      @servers.each { |s| s.stop }
      wait_for_all("stopped")
      @servers.each { |s| s.dns_name = nil }
    end

    def reboot_all
      wait_for_reboot = true
      @servers.each { |s| s.reboot(wait_for_reboot) }
    end

    # Run a script on server in the deployment
    # * server<~Server> the server to run the script on
    # * friendly_name<~String> string lookup for Hash @scripts_to_run.  @scripts_to_run must be a Hash containing an Executable with this key.
    def run_script(friendly_name, server)
      audit = server.run_executable(@scripts_to_run[friendly_name])
      audit.wait_for_completed
    end
    
  end
end
