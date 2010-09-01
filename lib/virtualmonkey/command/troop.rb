module VirtualMonkey
  module Command
    # This command does all the steps create/run/conditionaly destroy
    def self.troop
      options = Trollop::options do
        text "This command performs all the operations of the monkey in one execution.  Create/Run/Destroy"
        opt :file, "troop config, see config/troop/*sample.json for example format", :type => :string, :required => true
        opt :no_spot, "do not use spot instances"
        opt :create, "interactive mode: create troop config"
        opt :mci_override, "list of mcis to use instead of the ones from the server template. expects full hrefs.", :type => :string, :multi => true, :required => false
      end

      # PATHs SETUP
      features_dir = File.join(File.dirname(__FILE__), "..", "..", "..", "features")
      features_glob = Dir.glob(File.join(features_dir, "**"))
      features_glob = features_glob.collect { |c| File.basename(c) }

      config_dir = File.join(File.dirname(__FILE__), "..", "..", "..", "config")
      cloud_variables_glob = Dir.glob(File.join(config_dir, "cloud_variables", "**"))
      cloud_variables_glob = cloud_variables_glob.collect { |c| File.basename(c) }
      common_inputs_glob = Dir.glob(File.join(config_dir, "common_inputs", "**"))
      common_inputs_glob = common_inputs_glob.collect { |c| File.basename(c) }
      
      # CREATE NEW CONFIG
      if options[:create]
        troop_config = {}
        troop_config[:tag] = ask("What tag to use for creating the deployments?")
        troop_config[:server_template_ids] = ask("What Server Template ids would you like to use to create the deployments (comma delimited)?").split(",")
        troop_config[:server_template_ids].each {|st| st.strip!}

        troop_config[:runner] = 
          choose do |menu|
            menu.prompt = "What kind of deployment is this (runner type)?"
            menu.choice("MysqlRunner")
            menu.choice("SimpleRunner")
          end

        troop_config[:cloud_variables] =
          choose do |menu|
            menu.prompt = "Which cloud_variables config file?"
            menu.index = :number
            menu.choices(*cloud_variables_glob)
          end

        troop_config[:common_inputs] =
          choose do |menu|
            menu.prompt = "Which common_inputs config file?"
            menu.index = :number
            menu.choices(*common_inputs_glob)
          end

        troop_config[:feature] = 
          choose do |menu|
            menu.prompt = "Which feature file?"
            menu.index = :number
            menu.choices(*features_glob)
          end
        
        write_out = troop_config.to_json( :indent => "  ", 
                                          :object_nl => "\n",
                                          :array_nl => "\n" )
        File.open(options[:file], "w") { |f| f.write(write_out) }
        say("created config file #{options[:file]}")
        say("Done.")
      else
        # Execute Main
        config = JSON::parse(IO.read(options[:file]))
        # CREATE PHASE
        @dm = DeploymentMonk.new(config['tag'], config['server_template_ids'])
        @dm.variables_for_cloud = JSON::parse(IO.read(File.join(config_dir, "cloud_variables", config['cloud_variables'])))
        config['common_inputs'].each do |cipath|
          @dm.load_common_inputs(File.join(config_dir, "common_inputs", cipath))
        end  
        @dm.generate_variations(options)
        # RUN PHASE
        EM.run {
          cm = CukeMonk.new
          @dm.deployments.each do |deploy|
            cm.run_test(deploy, File.join(features_dir, config['feature']))
          end

          watch = EM.add_periodic_timer(10) {
            if cm.all_done?
              # DESTROY PHASE
              watch.cancel 
              cm.jobs.each do |job|
                # destroy on success only (keep failed deploys)
                if job.status == 0
                  runner = eval("VirtualMonkey::#{config['runner']}.new(job.deployment.nickname)")
                  puts "destroying successful deployment: #{runner.deployment.nickname}"
                  runner.stop_all(false)
                  runner.deployment.destroy
                end
              end    
            end
            cm.watch_and_report
          }
        }
      end
    end
  end
end
