require 'rubygems'
require 'erb'
require 'fog'
require 'fog/credentials'
require 'eventmachine'
require 'right_popen'

class CukeJob
  attr_accessor :status, :output, :logfile, :deployment
  def on_read_stdout(data)
    @output ||= ""
    @output << data
  end

  def on_read_stderr(data)
    @output ||= ""
    @output << data
  end
    
  def receive_data data
    @output += data
  end

  def unbind
    @status = get_status.exitstatus
  end

  def on_exit(status)
    @status = status.exitstatus
    File.open(@logfile, "a") { |f| f.write(@output) }
  end

  def run(deployment, cmd)
    RightScale.popen3(:command        => cmd,
                        :target         => self,
                        :environment    => {"DEPLOYMENT" => deployment},
                        :stdout_handler => :on_read_stdout,
                        :stderr_handler => :on_read_stderr,
                        :exit_handler   => :on_exit)
  end
end

class CukeMonk
  attr_accessor :jobs
  # Runs a cucumber test on a single Deployment
  # * deployment<~String> the nickname of the deployment
  # * feature<~String> the feature filename 
  def run_test(deployment, feature)
    new_job = CukeJob.new
    new_job.logfile = File.join(@log_dir, "#{deployment}.html")
    new_job.deployment = deployment
    ENV['REST_CONNECTION_LOG'] = "#{@log_dir}/#{deployment}.rest_connection.log"
    cmd = "cucumber #{feature} --out '#{new_job.logfile}' -f html"
    @jobs << new_job   
    puts "running #{cmd}"
    new_job.run(deployment, cmd)
  end

  def initialize()
    @jobs = []
    @log_dir = "log" 
    FileUtils.mkdir_p(@log_dir)
    @feature_dir = File.join(File.dirname(__FILE__), '..', '..', 'app', 'features')
  end
 
  # runs a feature on an array of deployments
  # * deployments<~Array> array of strings containing the nicknames of the deployments
  # * feature_name<~String> the feature filename 
  def run_tests(deployments,cmd)
    deployments.each { |d| run_test(d,cmd) }
  end

  def show_jobs
    passed = @jobs.select { |s| s.status == 0 }
    failed = @jobs.select { |s| s.status == 1 }
    running = @jobs.select { |s| s.status == nil }
    puts "#{passed.size} features passed.  #{failed.size} features failed.  #{running.size} features running."
  end

  def all_done?
    running = @jobs.select { |s| s.status == nil }
    running.size == 0 && @jobs.size > 0
  end

  def generate_reports
    passed = @jobs.select { |s| s.status == 0 }
    failed = @jobs.select { |s| s.status == 1 }
    running = @jobs.select { |s| s.status == nil }

    index = ERB.new  File.read(File.dirname(__FILE__)+"/index.html.erb")
    time = Time.now
    dir = time.strftime("%Y-%m-%d-%H-%M-%S")
    bucket_name = "virtual_monkey"

    ## upload to s3
    # setup credentials in ~/.fog
    s3 = Fog::AWS::S3.new(:aws_access_key_id => Fog.credentials[:aws_access_key_id], :aws_secret_access_key => Fog.credentials[:aws_secret_access_key])
    if directory = s3.directories.detect { |d| d.key == bucket_name } 
      puts "found directory, re-using"
    else
      directory = s3.directories.create(:key => bucket_name)
    end
    raise 'could not create directory' unless directory
    s3.put_object(bucket_name, "#{dir}/index.html", index.result(binding), 'x-amz-acl' => 'public-read', 'ContentType' => 'text/html')
 
    @jobs.each do |j|
      s3.put_object(bucket_name, "#{dir}/#{File.basename(j.logfile)}", IO.read(j.logfile), 'x-amz-acl' => 'public-read', 'ContentType' => 'text/html')
    end
    
    msg = <<END_OF_MESSAGE
    results avilable at http://s3.amazonaws.com/#{bucket_name}/#{dir}/index.html
END_OF_MESSAGE
    puts msg
  end
  
end

