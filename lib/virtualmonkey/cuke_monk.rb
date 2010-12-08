require 'rubygems'
require 'erb'
require 'fog'
require 'fog/credentials'
require 'eventmachine'
require 'right_popen'

class CukeJob
  attr_accessor :status, :output, :logfile, :deployment, :rest_log

  def link_to_rightscale
    i = deployment.href.split(/\//).last
    d = deployment.href.split(/\./).first.split(/\//).last
    "https://#{d}.rightscale.com/deployments/#{i}#auditentries"
  end

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
                        :environment    => {"DEPLOYMENT" => deployment.nickname,
                                            "AWS_ACCESS_KEY_ID" => Fog.credentials[:aws_access_key_id],
                                            "AWS_SECRET_ACCESS_KEY" => Fog.credentials[:aws_secret_access_key],
                                            "REST_CONNECTION_LOG" => @rest_log,
                                            "AUTO_MONKEY" => "1",
                                            "MONKEY_NO_RESUME" => "1"},
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
  def run_test(deployment, feature, break_point = 1000000)
    new_job = CukeJob.new
    new_job.logfile = File.join(@log_dir, "#{deployment.nickname}.log")
    new_job.rest_log = "#{@log_dir}/#{deployment.nickname}.rest_connection.log"
    new_job.deployment = deployment
    cmd = "bin/grinder #{feature} #{break_point} '#{new_job.logfile}'"
    @jobs << new_job
    puts "running #{cmd}"
    new_job.run(deployment, cmd)
  end

  def initialize()
    @jobs = []
    @passed = []
    @failed = []
    @running = []
    dirname = Time.now.strftime("%Y/%m/%d/%H-%M-%S")
    @log_dir = File.join("log", dirname)
    @log_started = dirname
    FileUtils.mkdir_p(@log_dir)
    @feature_dir = File.join(File.dirname(__FILE__), '..', '..', 'features')
  end
 
  # runs a feature on an array of deployments
  # * deployments<~Array> array of strings containing the nicknames of the deployments
  # * feature_name<~String> the feature filename 
  def run_tests(deployments,cmd)
    deployments.each { |d| run_test(d,cmd) }
  end

  def watch_and_report
    old_passed = @passed
    old_failed = @failed
    @passed = @jobs.select { |s| s.status == 0 }
    @failed = @jobs.select { |s| s.status == 1 }
    @running = @jobs.select { |s| s.status == nil }
      puts "#{@passed.size} features passed.  #{@failed.size} features failed.  #{@running.size} features running."
    if old_passed != @passed || old_failed != @failed
      status_change_hook
    end
  end

  def status_change_hook
    generate_reports
    if all_done?
      puts "monkey done."
      EM.stop
    end
  end

  def all_done?
    running = @jobs.select { |s| s.status == nil }
    running.size == 0 && @jobs.size > 0
  end

  def generate_reports
    passed = @jobs.select { |s| s.status == 0 }
    failed = @jobs.select { |s| s.status == 1 }
    running = @jobs.select { |s| s.status == nil }
    report_on = @jobs.select { |s| s.status == 0 || s.status == 1 }
    index = ERB.new  File.read(File.dirname(__FILE__)+"/index.html.erb")
    bucket_name = "virtual_monkey"

    ## upload to s3
    # setup credentials in ~/.fog
    s3 = Fog::AWS::Storage.new(:aws_access_key_id => Fog.credentials[:aws_access_key_id_test], :aws_secret_access_key => Fog.credentials[:aws_secret_access_key_test])
    if directory = s3.directories.detect { |d| d.key == bucket_name } 
      puts "found directory, re-using"
    else
      directory = s3.directories.create(:key => bucket_name)
    end
    raise 'could not create directory' unless directory
    s3.put_object(bucket_name, "#{@log_started}/index.html", index.result(binding), 'x-amz-acl' => 'public-read', 'Content-Type' => 'text/html')
 
    report_on.each do |j|
      s3.put_object(bucket_name, "#{@log_started}/#{File.basename(j.logfile)}", IO.read(j.logfile), 'Content-Type' => 'text/plain', 'x-amz-acl' => 'public-read')
      s3.put_object(bucket_name, "#{@log_started}/#{File.basename(j.rest_log)}", IO.read(j.rest_log), 'Content-Type' => 'text/plain', 'x-amz-acl' => 'public-read')
    end
    
    msg = <<END_OF_MESSAGE
    new results avilable at http://s3.amazonaws.com/#{bucket_name}/#{@log_started}/index.html\n-OR-\nin #{@log_dir}/index.html"
END_OF_MESSAGE
    puts msg
  end
  
end

