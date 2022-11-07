#!/usr/bin/env ruby
require 'digest'
require "uri"
require 'net/http'
auth_connection = nil
uri = URI("http://0.0.0.0:8888/auth")
retries = 0
messages = {"retrying"=> "Your connection is retrying\n", "failed"=> "Your connection request is failed\n", "3"=> "Listing on http://0.0.0.0:8888/auth\n", "4"=> "Listing on http://0.0.0.0:8888/users\n", "success"=> "Request was successed\n"}

# Authetication
begin
	unless auth_connection
		print messages["3"]
		auth_connection = Net::HTTP.start(uri.host, uri.port, read_timeout: 1)
	end
	res =  auth_connection.request_get(uri.path)
	token = res["Badsec-Authentication-Token"]
rescue Errno::ECONNREFUSED, Net::ReadTimeout => e
	if (retries += 1) <= 3
		print messages["retrying"]
		sleep(retries)
		retry
	else
		print messages["failed"]
	end
ensure
	if auth_connection
		print messages["success"]
		auth_connection.finish
	end
end

# fetching users data using api 
user_connection = nil
#sh256 convert
data = Digest::SHA256.hexdigest("#{token}"+"/users")
uri = URI("http://0.0.0.0:8888/users")
begin
		request = nil
		unless user_connection
			print messages["4"]
			request = Net::HTTP::Get.new(uri)
			request["X-Request-Checksum"] = data
			user_connection = Net::HTTP.start(uri.host, uri.port, read_timeout: 1)
		end
		res =  user_connection.request(request).body
		users_data = res.gsub("\n", ',').split(',')
		print users_data.inspect
	rescue Errno::ECONNREFUSED, Net::ReadTimeout => e
		if (retries += 1) <= 3
			print messages["retrying"]
			sleep(retries)
			retry
		else
			print messages["failed"]
		end
	ensure
		if user_connection
			user_connection.finish
		end
	end