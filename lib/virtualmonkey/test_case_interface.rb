module VirtualMonkey
  module TestCaseInterface
    def set_var(sym, *args)
      behavior(sym, *args)
    end

    def behavior(sym, *args)
      begin
        rerun_test
        #pre-command
        populate_settings unless @populated
        #command
        result = __send__(sym, *args)
        #post-command
        continue_test
      rescue Exception => e
        dev_mode?(e)
      end while @rerun_last_command.pop
      result
    end

    def verify(method, expectation, *args)
      if expectation =~ /((exception)|(error)|(fatal)|(fail))/i
        expect = "fail"
        error_msg = expectation.split(":")[1..-1].join(":")
      elsif expectation =~ /((success)|(succeed)|(pass))/i
        expect = "pass"
      elsif expectation =~ /nil/i
        expect = "nil"
      else
        raise 'Syntax Error: verify expects a "pass", "fail", or "nil"'
      end

      begin
        rerun_test
        result = __send__(command, *args)
        if expect != "pass" and not (result == nil and expect == "nil")
          raise "FATAL: Failed verification"
        end
        continue_test
      rescue Exception => e
        if not ("#{e}" =~ /#{error_msg}/ and expect == "fail")
          dev_mode?(e)
        end
      end while @rerun_last_command.pop
    end

    def probe(server, command, &block)
      # run command on servers matching "server" over ssh
      result = ""
      @servers.select { |s| s.nickname =~ /#{server}/ }.each { |s|
        begin
          rerun_test
          result_temp = s.spot_check_command(command)
          if not yield(result_temp[:output])
            raise "FATAL: Server #{s.nickname} failed probe. Got #{result_temp[:output]}"
          end
          continue_test
        rescue Exception => e
          dev_mode?(e)
        end while @rerun_last_command.pop
        result += result_temp[:output]
      }
    end

    private

    def dev_mode?(e)
      if not ENV['MONKEY_NO_DEBUG'] =~ /true/i
        puts e
        puts "Pausing for debugging..."
        debugger
      else
        exception_handle(e)
      end
    end

    def exception_handle(e)
      puts "ATTENTION: Using default exception_handle(e). This can be overridden in mixin classes."
      if e.message =~ /Insufficient capacity/
        puts "Got \"#{e.message}\". Retrying...."
        sleep 60
      else
        raise e
      end
    end

    def help
      puts "Here are some of the wrapper methods that may be of use to you in your debugging quest:\n"
      puts "behavior(sym, *args): Pass the method name (as a symbol or string) and the optional arguments"
      puts "                      that you wish to pass to that method; behavior() will call that method"
      puts "                      with those arguments while handling nested exceptions, retries, and"
      puts "                      debugger calls.\n"
      puts "                      Examples:"
      puts "                        behavior(:launch_all)"
      puts "                        behavior(:launch_set, 'Load Balancer')\n"
      puts "verify(sym, expectation_string, *args): Pass the method name (as a symbol or string), the expected" 
      puts "                                        result, and any arguments to pass to that method. The"
      puts "                                        expectation_string should consist of 'Error: MyRegex',"
      puts "                                        'Pass', or 'nil'. 'Error: MyRegex' tells verify() that it"
      puts "                                        should expect an exception to be raised, and the message "
      puts "                                        or exception name should match /MyRegex/. 'Pass' tells"
      puts "                                        verify() that it should expect the method to return normally,"
      puts "                                        and 'nil' tells verify() that it should expect the method to"
      puts "                                        return nil.\n"
      puts "                                        Example:"
      puts "                                          verify(:launch_all, 'Error: execution expired')\n"
      puts "probe(server_regex, shell_command, &block): Provides a one-line interface for running a command on"
      puts "                                            a set of servers and verifying their output. The block"
      puts "                                            should take one argument, the output string from one of"
      puts "                                            the servers, and return true or false based on however"
      puts "                                            the developer wants to verify correctness.\n"
      puts "                                            Examples:"
      puts "                                              probe('.*', 'ls') { |s| puts s }"
      puts "                                              probe('.*', 'uname -a') { |s| s =~ /x64/ }\n"
      puts "continue_test: Disables the retry loop that reruns the last command (the current command that you're"
      puts "               debugging.\n"
      puts "help: Prints this help message."
    end

    def populate_settings
      @servers.each { |s| s.settings }
      lookup_scripts
      @populated = 1
    end

    def object_behavior(obj, sym, *args)
      begin
        rerun_test
        #pre-command
        populate_settings unless @populated
        #command
        result = obj.__send__(sym, *args)
        #post-command
        continue_test
      rescue Exception => e
        dev_mode?(e)
      end while @rerun_last_command.pop
      result
    end

    def rerun_test
      @rerun_last_command.push(true)
    end

    def continue_test
      @rerun_last_command.pop
      @rerun_last_command.push(false)
    end
  end
end
