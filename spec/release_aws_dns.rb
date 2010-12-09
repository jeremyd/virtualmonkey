require File.join(File.dirname(__FILE__), "spec_helper")
require 'ruby-debug'

x=SharedDns.new("virtualmonkey_awsdns")
x.release_all
