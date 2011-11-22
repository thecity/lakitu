require './config_cloud'

puts "Starting Lakitu"

required_vars = %w(HEROKU_USER HEROKU_PASS HEROKU_APP 
                   AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY 
                   RDS_DATABASE_ID
                   MEMCACHED_NAME_PREFIX 
                   RESQUE_REDIS_URL RESQUE_REDIS_NAMESPACE
                   SENDGRID_DOMAIN SENDGRID_USERNAME SENDGRID_PASSWORD
                   ALERTS_EMAIL
                   REDIS_SERVERS REDIS_CONFIG_CMDS REDIS_MEMORY_THRESHOLD)
                   # If dyno scaling was on you'd need these too.
                   # NEW_RELIC_API_KEY NEW_RELIC_ID NEW_RELIC_APPID 
                   
required_vars.each do |var|
  raise "Missing required environment variable #{var}" unless ENV.include?(var)
end

# Synced logging for puts
STDERR.sync = STDOUT.sync = true

every(2.minute,  'worker_scaling')               { WORKER_SCALING_QUEUE.push({}) }
# This didn't work right.
# every(5.minute,  'dyno_scaling')               { DYNO_SCALING_QUEUE.push({})   }

# staging doesn't need this
if ENV['HEROKU_APP'] == 'thecity-production'
  every(10.minute, 'ec2_checking')                 { EC2_CHECKING_QUEUE.push({})   }
end

every(15.minute, 'resque_checking')              { RESQUE_CHECKING_QUEUE.push({})}
every(15.minute, 'redis_checking')               { REDIS_CHECKING_QUEUE.push({}) }
every(1.day,     'rds_snapshot', :at => '11:00') { RDS_SNAPSHOT_QUEUE.push({}) } #UTC suckas