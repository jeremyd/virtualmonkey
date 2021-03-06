module VirtualMonkey
  module Command

# monkey clone --deployment name --feature testcase.rb --breakpoint 4 --copies 7
    def self.clone
      options = Trollop::options do
        opt :deployment, "regex string to use for matching deployment", :type => :string, :short => '-d', :required => true
        opt :feature, "path to feature(s) to run against the deployments", :type => :string
        opt :breakpoint, "feature file line to stop at", :type => :integer, :short => '-b'
        opt :copies, "number of copies to make (default is 1)", :type => :integer, :short => '-c'
      end

      options[:copies] = 1 unless options[:copies] > 1
      options[:no_resume] = true
      dm = DeploymentMonk.new(options[:deployment])
      if dm.deployments.length > 1
        raise "FATAL: Ambiguous Regex; more than one deployment matched /#{options[:deployment]}/"
      elsif dm.deployments.length < 1
        raise "FATAL: Ambiguous Regex; no deployment matched /#{options[:deployment]}/"
      end
      origin = dm.deployments.first
      do_these ||= []
      # clone deployment
      for i in 1 .. options[:copies]
        new_deploy = origin.clone
        new_deploy.nickname = "#{origin.nickname}-clone-#{i}"
        new_deploy.save
        do_these << new_deploy
      end

      # run to breakpoint
      if options[:feature]
        EM.run {
          cm = CukeMonk.new
          cm.options = options
          do_these.each do |deploy|
            cm.run_test(deploy, options[:feature])
          end

          watch = EM.add_periodic_timer(10) {
            if cm.all_done?
              watch.cancel
            end
            cm.watch_and_report
          }
        }
      end
    end
  end
end
