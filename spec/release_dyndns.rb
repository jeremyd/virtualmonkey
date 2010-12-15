require File.join(File.dirname(__FILE__), "spec_helper")
require 'ruby-debug'

x=SharedDns.new("virtualmonkey_dyndns")
x.release_all
