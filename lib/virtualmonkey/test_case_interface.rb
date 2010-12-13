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
      end while @rerun_last_command.last
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
        raise 'Syntax Error: verify expects a "pass", "fail", or "quiet"'
      end

      begin
        rerun_test
        result = __send__(command, *args)
        if expect != "pass" and not (result == nil and expect == "nil")
          raise "FATAL: Failed verification"
        end
        continue_test
      rescue Exception => e
        if not (e.message =~ /#{error_msg}/ and expect == "fail")
          dev_mode?(e)
        end
      end while @rerun_last_command.last
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
        end while @rerun_last_command.last
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
        sleep 10
      else
        raise e
      end
    end

    def populate_settings
      # @servers.each { |s| s.settings }
      # lookup_scripts
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
      end while @rerun_last_command.last
      result
    end

    def rerun_test
      @rerun_last_command.push(true)
    end

    def continue_test
      @rerun_last_command.pop
    end
  end
end
