module VirtualMonkey
  module Command
    def self.list
      options = Trollop::options do
        opt :tags, "List deployment set tags"
      end
      if options[:tags]
        all = Deployment.find(:all) {|d| d.nickname =~ /#{options[:tags]}/}
      else
        all = Deployment.find(:all)
      end
      all_names = all.map { |d| d.nickname }
      puts all_names.join("\n")
    end
  end 
end
