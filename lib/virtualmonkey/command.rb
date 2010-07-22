#!/usr/bin/env ruby
require 'rubygems'
require 'trollop'
require 'highline/import'
require 'virtualmonkey/command/create'
require 'virtualmonkey/command/destroy'
require 'virtualmonkey/command/run'
require 'virtualmonkey/command/list'

module VirtualMonkey
  module Command
    # Parses the initial command string, removing it from ARGV, then runs command.
    def self.go
      command = ARGV.shift
      case command
        when "create"
          VirtualMonkey::Command.create
        when "destroy"
          VirtualMonkey::Command.destroy
        when "run"
          VirtualMonkey::Command.run
        when "list"
          VirtualMonkey::Command.list
        when "help" || "--help" || "-h"
          "Help usage: monkey <command> --help"
        else
          STDERR.puts "Invalid command #{command}: You need to specify a command for monkey: create, destroy, list, run or help\n"
          exit(1)
      end
    end
  end
end
