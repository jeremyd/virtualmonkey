class SharedDns
  attr_accessor :reservation
  attr_accessor :owner

  def initialize
    @sdb = Fog::AWS::SimpleDB.new(:aws_access_key_id => Fog.credentials[:aws_access_key_id], :aws_secret_access_key => Fog.credentials[:aws_secret_access_key])
    @domain = "virtualmonkey_shared_resources"
    @reservation = nil
  end

    # set dns inputs on a deployment to match the current reservation
  # * deployment<~Deployment> the deployment to set inputs on
  def set_dns_inputs(deployment)
    sdb_result = @sdb.get_attributes(@domain, @reservation)

    set_these = sdb_result.body['Attributes'].reject {|k,v| k == 'owner'}
    set_these.each do |key,val|
      deployment.set_input(key, val.to_s)
    end
  end

  def reserve_dns(owner, timeout = 0)
    result = @sdb.select("SELECT * from #{@domain} where owner = 'available'")
    return false if result.body["Items"].empty?
    item_name = result.body["Items"].keys.first
    response = @sdb.put_attributes(@domain, item_name, {'owner' => owner}, :expect => {'owner' => "available"}, :replace => ['owner'])
    @owner = owner
    @reservation = item_name
  rescue Excon::Errors::ServiceUnavailable
    retry_reservation(timeout)
  rescue Excon::Errors::Conflict
    retry_reservation(timeout)
  end

  def retry_reservation(timeout)
    STDOUT.flush
    if timeout > 20 
      return false
    end
    sleep(5)
    reserve_dns(timeout + 1)
  end

  def release_all
    result = @sdb.select("SELECT * from #{@domain}")
    result.body['Items'].keys.each do |item_name|
      @sdb.put_attributes(@domain, item_name, {"owner" => "available"}, :replace => ["owner"])
    end
  end

  def release_dns(res = @reservation)
    raise "FATAL: could not release dns because there was no @reservation" unless res
    @sdb.put_attributes(@domain, res, {"owner" => "available"}, :replace => ["owner"]) 
    @reservation = nil
  end
end


