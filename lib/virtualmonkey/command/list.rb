module VirtualMonkey
  module Command
    def self.list
      options = Trollop::options do
        opt :tags, "List deployment set tags"
      end

      if options[:tags]
        all_names = Deployment.find(:all).map &:nickname
        puts all_names.join("\n")
      end
    end
  end 
end
