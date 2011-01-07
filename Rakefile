require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "virtualmonkey"
    gem.summary = %Q{testing cluster deployments}
    gem.description = %Q{monkey see, monkey do, monkey repeat}
    gem.email = "jeremy@rightscale.com"
    gem.homepage = "http://github.com/jeremyd/virtualmonkey"
    gem.authors = ["Jeremy Deininger"]
    gem.add_development_dependency "rspec", ">= 1.2.9"
    gem.add_development_dependency "jeweler"
    gem.add_development_dependency "gemedit"
    gem.add_dependency('json')
    gem.add_dependency('trollop')
    gem.add_dependency "rest_connection"
    gem.add_dependency "fog"
    gem.add_dependency "highline"
    gem.add_dependency "rspec"
    gem.add_dependency "eventmachine"
    gem.add_dependency "right_popen"
    gem.add_dependency "ruby-debug"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

#new rspec
#require 'rspec/core/rake_task'
#RSpec::Core::RakeTask.new do |t|
#  t.rspec_opts = ["-c", "-f progress", "-r ./spec/spec_helper.rb"]
#  t.pattern = 'spec/**/*_spec.rb'
#end

task :spec => :check_dependencies

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "virtualmonkey #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
