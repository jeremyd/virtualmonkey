module VirtualMonkey
  module Command
  
# monkey destroy --tag unique_tag
    def self.destroy
      options = Trollop::options do
        opt :tag, "Tag to match prefix of the deployments to destroy.", :type => :string, :required => true, :short => '-t'
        opt :terminate, "Terminate using the specified runner", :type => :string, :required => true, :short => "-r"
        opt :no_delete, "only terminate, no deletion."
        opt :yes, "Turn off confirmation for destroy operation"
      end
      begin
        eval("VirtualMonkey::#{options[:terminate]}.new('fgasvgreng243o520sdvnsals')")
      rescue Exception => e
        raise e unless e.message =~ /Could not find a deployment named/
        options[:terminate] = "SimpleRunner" if options[:terminate]
      end
      @dm = DeploymentMonk.new(options[:tag])
#      nicks = @dm.deployments.map &:nickname
      nicks = @dm.deployments.map { |d| d.nickname }
      nicks.each { |n| say n }
      unless options[:yes]
        confirm = ask("Really destroy these #{nicks.length} deployments (y/n)?", lambda { |ans| true if (ans =~ /^[y,Y]{1}/) })
        raise "Aborting." unless confirm
      end

      global_state_dir = File.join(File.dirname(__FILE__), "..", "..", "..", "test_states")
      @dm.deployments.each do |deploy|
        @runner = eval("VirtualMonkey::#{options[:terminate]}.new(#{deploy.nickname})")
        @runner.behavior(:stop_all, false)
        state_dir = File.join(global_state_dir, deploy.nickname)
        if File.directory?(state_dir)
          puts "Deleting state files for #{deploy.nickname}..."
          Dir.new(state_dir).each do |state_file|
            if File.extname(state_file) =~ /((rb)|(feature))/
              File.delete(File.join(state_dir, state_file))
            end
          end
          Dir.rmdir(state_dir)
        end
      end

      @dm.destroy_all unless options[:no_delete]
      say "monkey done."
    end

  end
end
