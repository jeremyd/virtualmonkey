module VirtualMonkey
  module Command
  
# monkey destroy --tag unique_tag
    def self.destroy
      options = Trollop::options do
        opt :tag, "Tag to match prefix of the deployments to destroy.", :type => :string, :required => true, :short => '-t'
        opt :mysql, "Use special MySQL TERMINATE script, instead of normal shutdown of all servers."
        opt :yes, "Turn off confirmation for destroy operation"
      end
      @dm = DeploymentMonk.new(options[:tag])
#      nicks = @dm.deployments.map &:nickname
      nicks = @dm.deployments.map { |d| d.nickname }
      nicks.each { |n| say n }
      unless options[:yes]
        confirm = ask("Really destroy all these deployments (y/n)?", lambda { |ans| true if (ans =~ /^[y,Y]{1}/) })
        raise "Aborting." unless confirm
      end

      if options[:mysql]
        @dm.deployments.each do |deploy|
          @runner = VirtualMonkey::MysqlRunner.new(deploy.nickname)
          @runner.lookup_scripts
          @runner.stop_all
        end
      end
      @dm.destroy_all
      say "monkey done."
    end

  end
end
