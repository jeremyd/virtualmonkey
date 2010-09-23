module VirtualMonkey
  class HttpChecks
  
    # Tests http response code against given url
    #
    # === Parameters
    # url<String>:: A URL to perform http request against
    # expected_code<Integer>:: https code to match against curl response
    #
    # === Raises
    # Exceptions if retry attempts timeout
    def self.test_http_response(expected_code, url)
      cmd = "curl -w %{http_code} -s #{url} 2> /dev/null "
      puts cmd
      timeout=300
      begin
        status = Timeout::timeout(timeout) do
          while true
            response = `#{cmd}` 
            break if response.include?(expected_code)
            puts "Retrying..."
            sleep 5
          end
        end
      rescue Timeout::Error => e
        raise "ERROR: Query failed after #{timeout/60} minutes."
      end
    end



  end
end