require './config_cloud.rb'

use Rack::Auth::Basic do |username, password|
  [username, password] == [ENV['LAKITU_USERNAME'], ENV['LAKITU_PASSWORD']]
end


run Rack::URLMap.new \
  "/" => lambda { |env|
    [404, {'Content-Type' => 'text/html'}, ["<html><head><title>Nothing.</title></head><body>There's nothing to see here.</body></html>"]]
   },
  "/resque" => Resque::Server.new

