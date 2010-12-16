module VirtualMonkey
  module Command
    # This command does all the steps create/run/conditionaly destroy
    def self.troop
      options = Trollop::options do
        text "This command performs all the operations of the monkey in one execution.  Create/Run/Destroy"
        opt :file, "troop config, see config/troop/*sample.json for example format", :type => :string, :required => true
        opt :no_spot, "do not use spot instances"
        opt :step, "use the troop config file to do either: create, run, or destroy", :type => :string
        opt :tag, "add an additional tag to the deployments", :type => :string
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
      global_state_dir = File.join(File.dirname(__FILE__), "..", "..", "..", "test_states")
      options[:tag] += "-" if options[:tag]
      options[:tag] = "" unless options[:tag]
      
      # CREATE NEW CONFIG
      if options[:create]
        troop_config = {}
        troop_config[:tag] = ask("What tag to use for creating the deployments?")
        troop_config[:server_template_ids] = ask("What Server Template ids would you like to use to create the deployments (comma delimited)?").split(",")
        troop_config[:server_template_ids].each {|st| st.strip!}

        troop_config[:runner] = 
          choose do |menu|
            menu.prompt = "What kind of deployment is this (runner type)?"
            menu.choice("MysqlToolboxRunner")
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
        options[:step] = "all" unless options[:step]
        tag = options[:tag] + config['tag']

        # CREATE PHASE
        if options[:step] =~ /((all)|(create))/
          @dm = DeploymentMonk.new(tag, config['server_template_ids'])
          @dm.variables_for_cloud = JSON::parse(IO.read(File.join(config_dir, "cloud_variables", config['cloud_variables'])))
          config['common_inputs'].each do |cipath|
            @dm.load_common_inputs(File.join(config_dir, "common_inputs", cipath))
          end  
          @dm.generate_variations(options)
        end

        # RUN PHASE
        if options[:step] =~ /((all)|(run))/
          @dm = DeploymentMonk.new(tag) if options[:step] =~ /run/
          EM.run {
            @cm = CukeMonk.new
            @cm.options = {}
            @dm.deployments.each do |deploy|
              @cm.run_test(deploy, File.join(features_dir, config['feature']))
            end

            watch = EM.add_periodic_timer(10) {
              @cm.watch_and_report
              if @cm.all_done?
                # DESTROY PHASE
                watch.cancel 
                @cm.jobs.each do |job|
                  # destroy on success only (keep failed deploys)
                  if job.status == 0 and options[:step] =~ /all/
                    runner = eval("VirtualMonkey::#{config['runner']}.new(job.deployment.nickname)")
                    puts "destroying successful deployment: #{runner.deployment.nickname}"
                    runner.behavior(:stop_all, false)
                    state_dir = File.join(global_state_dir, runner.deployment.nickname)
                    if File.directory?(state_dir)
                      puts "Deleting state files for #{runner.deployment.nickname}..."
                      Dir.new(state_dir).each do |state_file|
                        if File.extname(state_file) =~ /((rb)|(feature))/
                          File.delete(File.join(state_dir, state_file))
                        end 
                      end 
                      Dir.rmdir(state_dir)
                    end 
                    runner.deployment.destroy
                  end
                end    
              end
            }
          }
        end

        if options[:step] =~ /destroy/
          @dm = DeploymentMonk.new(tag)
          @dm.deployments.each do |deploy|
            state_dir = File.join(global_state_dir, deploy.nickname)
            if File.directory?(state_dir)
              puts "Deleting state files for #{deploy.nickname}..."
              Dir.new(state_dir).each do |state_file|
                if File.extname(state_file) =~ /((rb)|(feature))/
                   File.delete(File.join(state_dir, state_file))
                end 
              end 
              Dir.rmdir(state_dir)
            end
          end
          @dm.destroy_all
        end
      end
      puts "Troop done."
    end
  end
end
