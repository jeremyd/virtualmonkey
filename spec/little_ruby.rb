require 'rubygems'
require 'virtualmonkey'

@sdb = Fog::AWS::SimpleDB.new(:aws_access_key_id => Fog.credentials[:aws_access_key_id_test], :aws_secret_access_key => Fog.credentials[:aws_secret_access_key_test])

@domain="virtualmonkey_awsdns"

29.times do |num|
  item_name="awsdns#{num}"
  attributes=
      {"SLAVE_DB_DNSID"=>["text:Z3AINKOIEY1X3X:testslave#{num}.aws.rightscale.com"],
       "MASTER_DB_DNSID"=>["text:Z3AINKOIEY1X3X:test#{num}.aws.rightscale.com"],
       "DNS_USER"=>["cred:AWS_ACCESS_KEY_ID_TEST"],
       "DNS_PASSWORD"=>["cred:AWS_SECRET_ACCESS_KEY_TEST"],
       "DNS_PROVIDER"=>["text:AwsDNS"],
       "owner"=>["available"],
       "MASTER_DB_DNSNAME"=>["text:test#{num}.aws.rightscale.com"]}
  response = @sdb.put_attributes(@domain, item_name, attributes)
end

