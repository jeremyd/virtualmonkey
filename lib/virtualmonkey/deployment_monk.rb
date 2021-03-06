require 'rubygems'
require 'rest_connection'

class DeploymentMonk
  attr_accessor :common_inputs
  attr_accessor :variables_for_cloud
  attr_accessor :deployments
  attr_reader :tag

  def from_tag
    variations = Deployment.find_by(:nickname) {|n| n =~ /^#{@tag}/ }
    puts "loading #{variations.size} deployments matching your tag"
    return variations
  end

  def initialize(tag, server_templates = [], extra_images = [])
    @clouds = ["1","2","3","4", "232"]
    @cloud_names = { "1" => "ec2-east", "2" => "ec2-eu", "3" => "ec2-west", "4" => "ec2-ap", "232" => "rackspace"}
    @tag = tag
    @deployments = from_tag
    @server_templates = []
    @common_inputs = {}
    @variables_for_cloud = {}
    raise "Need either populated deployments or passed in server_template ids" if server_templates.empty? && @deployments.empty?
    if server_templates.empty?
      puts "loading server templates from servers in the first deployment"
      @deployments.first.servers.each do |s|
        server_templates << s.server_template_href.split(/\//).last.to_i
      end
    end
    server_templates.each do |st|
      @server_templates << ServerTemplate.find(st.to_i)
    end

    @image_count = 0
    @server_templates.each do |st|
      new_st = ServerTemplateInternal.new(:href => st.href)
      st.multi_cloud_images = new_st.multi_cloud_images
      @image_count = st.multi_cloud_images.size if st.multi_cloud_images.size > @image_count
    end
  end

  def generate_variations(options = {})
    if options[:mci_override] && !options[:mci_override].empty?
      @image_count = options[:mci_override].size
    end
    @image_count.times do |index|
      @clouds.each do |cloud|
        if @variables_for_cloud[cloud] == nil
          puts "variables not found for cloud #{cloud} skipping.."
          next
        end
        dep_tempname = "#{@tag}-#{@cloud_names[cloud]}-#{rand(1000000)}-"
        dep_image_list = []
        new_deploy = Deployment.create(:nickname => dep_tempname)
        @deployments << new_deploy
        @server_templates.each do |st|
          server_params = { :nickname => "tempserver-#{rand(1000000)}-#{st.nickname}", 
                            :deployment_href => new_deploy.href, 
                            :server_template_href => st.href, 
                            :cloud_id => cloud
                            #:ec2_image_href => image['image_href'], 
                            #:instance_type => image['aws_instance_type'] 
                          }
          
          server = Server.create(server_params.merge(@variables_for_cloud[cloud]))
          # since the create call does not set the parameters, we need to set them separate
          if server.respond_to?(:set_inputs)
            server.set_inputs(@variables_for_cloud[cloud]['parameters'])
          else
            @variables_for_cloud[cloud]['parameters'].each do |key,val|
              server.set_input(key,val)
            end
          end
         
          # uses a special internal call for setting the MCI on the server
          if options[:mci_override] && !options[:mci_override].empty?
            use_this_image = options[:mci_override][index]
            dep_image_list << MultiCloudImage.find(options[:mci_override][index]).name.gsub(/ /,'_')
          elsif st.multi_cloud_images[index]
            dep_image_list << st.multi_cloud_images[index]['name'].gsub(/ /,'_')
            use_this_image = st.multi_cloud_images[index]['href']
          else
            use_this_image = st.multi_cloud_images[0]['href']
          end
          #RsInternal.set_server_multi_cloud_image(server.href, use_this_image)
          sint = ServerInternal.new(:href => server.href)
          sint.set_multi_cloud_image(use_this_image)

          # finally, set the spot price
          unless options[:no_spot]
            server.reload
            server.settings
            if server.ec2_instance_type =~ /small/ 
              server.max_spot_price = "0.085"
            elsif server.ec2_instance_type =~ /large/
              server.max_spot_price = "0.38"
            end
            server.pricing = "spot"
            server.parameters = {}
            server.save
          end
        end
        new_deploy.nickname = dep_tempname + dep_image_list.uniq.join("_AND_")
        new_deploy.save
        @common_inputs.each do |key,val|
          new_deploy.set_input(key,val)
        end
      end
    end
  end

  def load_common_inputs(file)
    @common_inputs.merge! JSON.parse(IO.read(file))
  end

  def destroy_all
    @deployments.each do |v|
      v.reload
      v.servers.each { |s| s.stop }
    end 
    @deployments.each { |v| v.destroy }
    @deployments = []
  end

  def get_deployments
    deployments = []
    @deployments.each { |v| deployments << v.nickname }
    deployments 
  end

end
