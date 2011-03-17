require 'heroku'
require 'fog'
require 'resque'
require 'chef'

redis_uri = ENV["REDIS_URL"]? URI.parse(ENV["REDIS_URL"]) : URI.parse("redis://localhost:6379")
REDIS = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
Resque.redis = REDIS

# This may need to move in the app, resque rapid sample times to scale
resque_scaler_config = 
  [
    { :workers => 1,  :job_count => 0  },
    { :workers => 3,  :job_count => 25 },
    { :workers => 5,  :job_count => 60 },
    { :workers => 8,  :job_count => 200 },
    { :workers => 10, :job_count => 500 },
    { :workers => 15, :job_count => 1000 },
    { :workers => 20, :job_count => 5000 }
  ]
HerokuResqueAutoScale::Scaler.scaling_configuration = scaler_config

NEWRELIC = NewRelicClient.new(ENV['NEW_RELIC_API_KEY'], ENV['NEW_RELIC_ID'], ENV['NEW_RELIC_APPID'])

dyno_scaler_config = 
  [
    { :cpu => 0.01, :dynos => 2  },
    { :cpu => 0.10, :dynos => 5  },
    { :cpu => 0.5,  :dynos => 12 },
    { :cpu => 0.7,  :dynos => 20 },
  ]
HerokuDynoAutoScale::Scaler.scaling_configuration = dyno_scaler_config

RESQUE_QUEUE_LIMIT = 100_000