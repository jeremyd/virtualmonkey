require 'eventmachine'
module VirtualMonkey
  module Command
  
# trollop supports Chronic for human readable dates. use with run command for delayed run?

# monkey run --feature --tag --only <regex to match on deploy nickname>
    def self.run
      options = Trollop::options do
        opt :feature, "path to feature(s) to run against the deployments", :type => :string, :required => true
        opt :tag, "Tag to match prefix of the deployments.", :type => :string, :required => true
        opt :only, "regex string to use for subselection matching on deployments.  Eg. --only x86_64", :type => :string
      end
      EM.run {
        cm = CukeMonk.new
        dm = DeploymentMonk.new(options[:tag])
        if options[:only]
          do_these = dm.deployments.select { |s| s.nickname =~ /#{options[:only]}/ }
        else
          do_these = dm.deployments
        end
        do_these.each do |deploy|
          cm.run_test(deploy, options[:feature])
        end

        watch = EM.add_periodic_timer(10) {
          watch.cancel if cm.all_done?
          cm.watch_and_report
        }

      }
    end
  end
end
