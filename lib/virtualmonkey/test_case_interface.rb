module VirtualMonkey
  module TestCaseInterface
    def set_var(sym, *args)
      behavior(sym, *args)
    end

    def behavior(sym, *args)
      begin
        @rerun_last_command = false
        #pre-command
        populate_settings unless @populated
        #command
        result = __send__(sym, *args)
        #post-command
      rescue Exception => e
        dev_mode?(e)
      end while @rerun_last_command
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
        @rerun_last_command = false
        result = __send__(command, *args)
        if expect != "pass" and not (result == nil and expect == "nil")
          raise "FATAL: Failed verification"
        end
      rescue Exception => e
        if not (e.message =~ /#{error_msg}/ and expect == "fail")
          dev_mode?(e)
        end
      end while @rerun_last_command
    end

    def probe(server, command, &block)
      # run command on servers matching "server" over ssh
      result = ""
      @servers.select { |s| s.nickname =~ /#{server}/ }.each { |s|
        begin
          @rerun_last_command = false
          result_temp = s.spot_check_command(command)
          if not yield(result_temp)
            raise "FATAL: Server #{s.nickname} failed probe. Got #{result_temp}"
          end
        rescue Exception => e
          dev_mode?(e)
        end while @rerun_last_command
        result += result_temp
      }
    end

    def dev_mode?(e)
      if not ENV['MONKEY_NO_DEBUG'] =~ /true/i
        puts "Got \"#{e.message}\". Pausing for debugging..."
        @rerun_last_command = true
        debugger
      else
        exception_handle(e)
      end
    end

    def exception_handle(e)
      puts "WARNING: exception_handle(e) is undefined, this must be set in mixin classes"
      if e.message =~ /Insufficient capacity/
        sleep 10
        @rerun_last_command = true
      else
        raise e
      end
    end

    def populate_settings
      # @servers.each { |s| s.settings }
      # lookup_scripts
      @populated = 1
    end
  end
end
