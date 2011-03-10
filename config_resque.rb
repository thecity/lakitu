require 'uri'
require 'redis'
require 'resque'
require 'resque_scheduler'
require 'yaml'

uri = ENV["REMOTE_REDIS_URL"]? URI.parse(ENV["REMOTE_REDIS_URL"]) : URI.parse("redis://localhost:6379")

REDIS = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)

Resque.redis = REDIS
# If you wanted to use Resque for fine-grained job scheduling, you'd load the schedule here.
# Resque.schedule = YAML.load_file(File.join(File.dirname(__FILE__), 'resque_schedule.yml'))

