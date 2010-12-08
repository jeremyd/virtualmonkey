require 'eventmachine'
module VirtualMonkey
  module Command
  
# trollop supports Chronic for human readable dates. use with run command for delayed run?

# monkey run --feature --tag --only <regex to match on deploy nickname>
    def self.run
      options = Trollop::options do
        opt :feature, "path to feature(s) to run against the deployments", :type => :string, :required => true
        opt :breakpoint, "feature file line to stop at", :type => :integer, :short => '-b'
        opt :tag, "Tag to match prefix of the deployments.", :type => :string, :required => true, :short => "-t"
        opt :only, "regex string to use for subselection matching on deployments.  Eg. --only x86_64", :type => :string
        opt :terminate, "Terminate if feature successfully completes. (No destroy)", :short => "-r"
        opt :mysql, "Use special MySQL TERMINATE script, instead of normal shutdown of all servers. Specify --terminate also", :short => "-m"
        opt :no_resume, "Do not use current test-in-progress, start from scratch", :short => "-n"
      end
      EM.run {
        cm = CukeMonk.new
        dm = DeploymentMonk.new(options[:tag])
        if options[:only]
          do_these = dm.deployments.select { |s| s.nickname =~ /#{options[:only]}/ }
        else
          do_these = dm.deployments
        end
        cm.options = options
        do_these.each do |deploy|
          cm.run_test(deploy, options[:feature])
        end

        watch = EM.add_periodic_timer(10) {
          if cm.all_done?
            watch.cancel
            if options[:terminate]
              cm.jobs.each do |job|
                if job.status == 0
                  if options[:mysql]
                    @runner = VirtualMonkey::MysqlRunner.new(job.deployment.nickname)
                  else
                    @runner = VirtualMonkey::SimpleRunner.new(job.deployment.nickname)
                  end
                  @runner.behavior(:stop_all, false)
                end
              end
            end
          end
          cm.watch_and_report
        }

      }
    end
  end
end
