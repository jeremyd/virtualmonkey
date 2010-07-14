require 'ruby-debug'

module VirtualMonkey
  module EBS
    include VirtualMonkey::DeploymentRunner
    attr_accessor :stripe_count

    # sets the stripe count for the deployment
    # * count<~String> eg. "3"
    def set_variation_stripe_count(count)
      @stripe_count = count
      @deployment.set_input("EBS_STRIPE_COUNT", "text:#{@stripe_count}")
    end

    # sets the volume size n GB for the runner
    # * kind<~Num> 
    def set_variation_volume_size(size)
      @volume_size = size
    end

    # take the lineage name, find all snapshots and sleep until none are in the pending state.
    def wait_for_snapshots
      timeout=1500
      step=10
      while timeout > 0
        puts "Checking for snapshot completed"
        snapshots =Ec2EbsSnapshot.find_by_cloud_id(@servers.first.cloud_id).select { |n| n.nickname =~ /#{@lineage}.*$/ }
        status= snapshots.map &:aws_status
        break unless status.include?("pending")
        sleep step
        timeout -= step
      end
      raise "FATAL: timed out waiting for all snapshots in lineage #{@lineage} to complete" if timeout == 0
    end

    # * server<~Server> the server to backup
    def create_backup
      server = @servers.first
      run_script("backup",server)
      wait_for_snapshots
    end

  end
end
