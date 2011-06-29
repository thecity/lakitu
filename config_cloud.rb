require 'heroku'
require 'fog'
require 'resque'
require 'lib/alert_mailer'
require 'lib/heroku_dyno_auto_scale'
require 'lib/new_relic_client'

# API Access
NEWRELIC = NewRelicClient.new(ENV['NEW_RELIC_API_KEY'], ENV['NEW_RELIC_ID'], ENV['NEW_RELIC_APPID'])

EC2      = Fog::Compute.new(
            :provider => 'AWS', 
            :aws_access_key_id => ENV['AWS_ACCESS_KEY_ID'],
            :aws_secret_access_key => ENV['AWS_SECRET_ACCESS_KEY'])
            
HEROKU   = Heroku::Client.new(ENV['HEROKU_USER'], ENV['HEROKU_PASS'])

# Resque checking
Resque.redis = ENV['REDIS_URL']
RESQUE_QUEUE_LIMIT = 100_000

# NewRelic dyno scaling
dyno_scaler_config = 
  [
    { :rpm_range => 0..200,       :dynos => 2 },
    { :rpm_range => 201..500,     :dynos => 15 },
    { :rpm_range => 501..1000,    :dynos => 20 },
    { :rpm_range => 1001..20_000, :dynos => 30 },
  ]
HerokuDynoAutoScale::Scaler.scaling_configuration = dyno_scaler_config

Mail.defaults do
  delivery_method :smtp, { :address              => "smtp.sendgrid.net",
                           :port                 => 25,
                           :domain               => ENV['SENDGRID_DOMAIN'],
                           :user_name            => ENV['SENDGRID_USERNAME'],
                           :password             => ENV['SENDGRID_PASSWORD'],
                           :authentication       => 'plain'}
end