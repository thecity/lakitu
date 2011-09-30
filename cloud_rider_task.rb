require './config_cloud'

puts "Starting Lakitu"

required_vars = %w(HEROKU_USER HEROKU_PASS HEROKU_APP 
                   AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY 
                   RDS_DATABASE_ID
                   NEW_RELIC_API_KEY NEW_RELIC_ID NEW_RELIC_APPID 
                   MEMCACHED_NAME_PREFIX REDIS_URL
                   SENDGRID_DOMAIN SENDGRID_USERNAME SENDGRID_PASSWORD)
required_vars.each do |var|
  raise "Missing required environment variable #{var}" unless ENV.include?(var)
end

# Synced logging for puts
STDERR.sync = STDOUT.sync = true

every(2.minute,  'worker_scaling')             { WORKER_SCALING_QUEUE.push({}) }
every(5.minute,  'dyno_scaling')               { DYNO_SCALING_QUEUE.push({})   }
every(10.minute, 'ec2_checking')               { EC2_CHECKING_QUEUE.push({})   }
every(15.minute, 'resque_checking')            { RESQUE_CHECKING_QUEUE.push({})}
every(1.day,     'rds_snapshot', :at => '11:00') { RDS_SNAPSHOT_QUEUE.push({}) } #UTC suckas