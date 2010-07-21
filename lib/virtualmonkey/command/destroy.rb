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

      unless options[:yes]
        confirm = ask("Really destroy all these deployments? #{(@dm.variations.map &:nickname).join(',')}", lambda { |ans| true if (ans =~ /^[y,Y]{1}/) })
        raise "Aborting." unless confirm
      end

      if options[:mysql]
        @dm.deployments.each do |deploy|
          @runner = VirtualMonkey::MysqlRunner.new(deploy)
          @runner.lookup_scripts
          @runner.stop_all
        end
      end
      @dm.destroy_all
    end

  end
end
