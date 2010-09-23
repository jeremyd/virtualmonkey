module VirtualMonkey
  module UnifiedApplication
    # returns true if the http response contains the expected_string
    # * url<~String> url to perform http request
    # * expected_string<~String> regex compatible string used to match against the response output
    def test_http_response(expected_string, url, port)
      cmd = "curl -s #{url} 2> /dev/null "
      puts cmd
      timeout=300
      begin
        status = Timeout::timeout(timeout) do
          while true
            response = `#{cmd}` 
            break if response.include?(expected_string)
            puts "Retrying..."
            sleep 5
          end
        end
      rescue Timeout::Error => e
        raise "ERROR: Query failed after #{timeout/60} minutes."
      end
    end
    
    def run_unified_application_checks(run_on=@servers, port=8000)
      run_on.each do |server| 
        run_unified_application_check(server.dns_name, port)
      end
    end
    
    # this is where ALL the generic application server checks live, this could get rather long but for now it's a single method with a sequence of checks
    def run_unified_application_check(dns_name, port=8000)
      url_base = "#{dns_name}:#{port}"
      test_http_response("html serving succeeded", "#{url_base}/index.html", port) 
      test_http_response("configuration=succeeded", "#{url_base}/appserver/", port) 
      test_http_response("I am in the db", "#{url_base}/dbread/", port) 
      test_http_response("hostname=", "#{url_base}/serverid/", port) 
    end
    
  end
end
