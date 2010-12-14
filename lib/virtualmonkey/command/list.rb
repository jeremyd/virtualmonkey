module VirtualMonkey
  module Command
    def self.list
      options = Trollop::options do
        opt :tags, "List deployment set tags", :type => :string, :required => true
      end
      DeploymentMonk.new(options[:tags]).deployments.each { |d| puts d.nickname }
    end
  end 
end
