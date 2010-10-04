module VirtualMonkey
  module Command

# monkey create --server_template_ids 123,123 --common_inputs blah.json --feature simple.feature --tag unique_name --TBD:filter?
    def self.create
      options = Trollop::options do
        opt :server_template_ids, "ServerTemplate ids to use for creating the deployment.  Use one ID per server that you would like to be in the deployment.  Accepts space separated integers, or one argument per id. Eg. -s 23747 23747", :type => :integers, :required => true, :short => '-s'
        opt :common_inputs, "Paths to common input json files to load and set on all deployments.  Accepts space separated pathnames or one argument per pathname.  Eg. -c config/mysql_inputs.json -c config/other_inputs.json", :type => :strings, :required => true, :short => '-c'
        opt :tag, "Tag to use as nickname prefix for all deployments.", :type => :string, :required => true, :short => '-t'
        opt :cloud_variables, "Path to json file containing common inputs and variables per cloud. See config/cloud_variables.json.example", :type => :string, :required => true, :short => '-v'
        opt :no_spot, "Do not use spot instances"
      end
      @dm = DeploymentMonk.new(options[:tag], options[:server_template_ids])
      @dm.variables_for_cloud = JSON::parse(IO.read(options[:cloud_variables]))
      options[:common_inputs].each do |cipath|
        @dm.load_common_inputs(cipath)
      end  
      @dm.generate_variations(options)
    end
  end
end
