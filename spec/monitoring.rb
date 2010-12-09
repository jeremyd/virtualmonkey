require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'rubygems'
require 'virtualmonkey'

dep=VirtualMonkey::SimpleRunner.new(ENV['DEPLOYMENT'])
s= dep.servers.first
s.monitoring
mon=s.get_sketchy_data({'start'=>-180,'end'=>"-20",'plugin_name'=>"df",'plugin_type'=>"df-mnt"})
data=mon['data']
free=data['free']
raise "No df free data" unless free.length > 0
raise "DF not free" unless free[0]
