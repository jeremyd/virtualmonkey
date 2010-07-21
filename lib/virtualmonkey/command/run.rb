require 'eventmachine'
module VirtualMonkey
  module Command
  
# trollop supports Chronic for human readable dates. use with run command for delayed run?

# monkey run --feature --tag --only <regex to match on deploy nickname>
    def self.run
      options = Trollop::options do
        opt :feature, "path to feature(s) to run against the deployments", :type => :string, :required => true
        opt :tag, "Tag to match prefix of the deployments.", :type => :string, :required => true
        opt :only, "regex string(s) to use for subselection matching on deployments.  Eg. --only x86_64 --only East", :type => :strings
      end
      EM.run {
        cm = CukeMonk.new
        dm = DeploymentMonk.new(options[:tag])
        dm.deployments.each do |deploy|
          cm.run_test(deploy.nickname, options[:feature])
        end

        EM.add_periodic_timer(5) {
          cm.show_jobs
        }

        donetime = EM.add_periodic_timer(5) {
          if cm.all_done?
            donetime.cancel
            cm.generate_reports
            puts "monkey done."
            EM.stop
          end
        }
      }
    end
  end
end
