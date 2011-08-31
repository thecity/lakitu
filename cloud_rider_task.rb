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

handler { |job| Kernel.const_get(job).push({}) }

every 1.minute,  'WORKER_SCALING_QUEUE'
every 5.minute,  'DYNO_SCALING_QUEUE'
every 10.minute, 'EC2_CHECKING_QUEUE'
every 15.minute, 'RESQUE_CHECKING_QUEUE'
every 1.day, 'RDS_BACKUP_QUEUE', :at => '04:00'
