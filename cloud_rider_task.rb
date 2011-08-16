namespace 'lakitu' do
  desc 'Scale and check the city app stack'
  task :cloud_rider do
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
    
    run_count = 0
    while true
      puts 'sleeping...'
      sleep 1 * 60 # 1 minute sample time
      # sleep 1 # 1 second sample time, for testing
      run_count = (run_count + 1) % 60 # One hour worth of 1-minute intervals (0-59) you can check
      
      puts "Run number #{run_count}"
      
      
      # Run 1..59 (every minute)
      if run_count >= 0
        puts "Scaling workers..."
        workers = HerokuResqueScaler::Scaler.scale_workers
        puts "#{HerokuResqueScaler::Scaler.job_count} jobs, #{workers} workers."
      end
      
      # Run 0, 5, 10, 15... (every 5 minutes)
      if run_count % 5 == 0
        # DISABLED UNTIL THE #scale_dynos method is fixed!
        # puts 'Scaling dynos...'
        # # Scale the dynos based on RPM
        # if health = NEWRELIC.application_health
        #   dynos = HerokuDynoAutoScale::Scaler.scale_dynos(health[:rpm].to_i)
        #   puts "New Relic reported RPM of #{health[:rpm]}, dynos set to #{dynos}"
        # else
        #   puts "New Relic failed to deliver application health in a timely manner :("
        # end
      end
      # Run 0, 10, 20, 30, 40, 50 (every 10 minutes)        
      if run_count % 10 == 0
        puts 'Checking EC2 servers'
        # Check on our EC2 services.
        heroku_config = HEROKU.config_vars(ENV['HEROKU_APP'])
        
        # We're using redistogo. If we move to EC2 for Redis, these would be handy.
        
        # # Redis should be up
        # redis_master = EC2.servers.detect {|server| server.tags['Name'] == ENV['REDIS_MASTER_NAME'] }
        # if !redis_master.ready?
        #   AlertMailer.deliver_alert("Redis alert - master server down",
        #     "Redis Severity 2:\n\n Redis master server #{redis_server.id} is DOWN.") 
        # end
        # 
        # # Redis slave should be up
        # redis_slave = EC2.servers.detect {|server| server.tags['Name'] == ENV['REDIS_SLAVE_NAME'] }
        # if !redis_server.ready?
        #   AlertMailer.deliver_alert("Redis alert - slave server down",
        #     "Redis Severity 2:\n\n Redis slave server #{redis_server.id} is down!.") 
        # end
        
        # Site redis URL should match the current IP
        # redis_master_address = 'redis://' + redis_master.private_dns_name
        # if heroku_config['REDIS_URL'] != redis_master_address
        #   AlertMailer.deliver_alert("Redis alert - server misconfigured.", 
        #     "Redis Severity 2:\n\n Redis server address at #{redis_master_address} does not match #{heroku_config['REDIS_URL']} in #{ENV['HEROKU_APP']}.")
        # end
        
        # All the memcached servers should be up
        memcached_servers     = EC2.servers.find_all {|server| server.tags['Name'].include?(ENV['MEMCACHED_NAME_PREFIX']) }
        dead_memcached_server = memcached_servers.detect { |server| !server.ready? }
        
        unless dead_memcached_server.nil?
          puts "Memcached server #{dead_memcached_server.id} was found dead!"
          AlertMailer.deliver_alert("Memcached alert - server down", 
            "Memcached Severity 2:\n\n Memcached server #{dead_memcached_server.id} is DOWN.") 
        end
        
        # Heroku memcached server list should contain only listed servers
        memcached_addresses = memcached_servers.collect{|server| server.private_dns_name }
        if !heroku_config['MEMCACHE_SERVERS'].split(',').to_set.subset?(memcached_addresses.to_set)
          puts "Memcached servers were misconfigured: EC2 servers #{memcached_addresses.join(',')} " + \
               "does not match heroku config #{heroku_config['MEMCACHE_SERVERS']}"
          AlertMailer.deliver_alert("Memcached alert - server misconfigured.", 
            "Memcached Severity 2:\n\n Memcached server addresses of #{memcached_addresses.join(',')} " + \
            "does not match configuration of #{heroku_config['MEMCACHE_SERVERS']} in #{ENV['HEROKU_APP']}.")
        end
        
        puts "EC2 checked"
      end
      
      # Run 0, 15, 30, 45 (every 15 minutes)
      if run_count % 15 == 0
        puts "Checking Resque"
        # Check the resque queue size and, implicitly, redis connectivity
        is_error   = false
        queue_size = 0
        begin
          queue_size = Resque.info[:pending].to_i
          workers    = Resque.info[:workers].to_i
          
          if queue_size >= RESQUE_QUEUE_LIMIT or workers == 0
            puts "Queue or worker size error: Queue size: #{queue_size}, " + \
                  "expected < #{RESQUE_QUEUE_LIMIT}\n\n Workers #{workers}, expected > 0"
            AlertMailer.deliver_alert("Resque queue size alert", 
              "Resque Severity 2:\n\n " + \
              "Queue size: #{queue_size}, expected < #{RESQUE_QUEUE_LIMIT}\n" + \
              "Workers #{workers}, expected > 0.\n\n")
          end
        rescue Errno::ECONNREFUSED => e
          puts "Unable to connect to redis server #{Resque.redis_id}!"
          AlertMailer.deliver_alert("Resque connectivity error", 
            "Resque severity 2:\n\n " + \
            "Resque cannot communicate with Redis at URL #{Resque.redis_id}. This is bad!")
        end
        puts "Resque checked"
      end
      
      # Run 0, 20, 40, 0 (every 20 minutes)
      if run_count % 20 == 0
        # Nothing yet.
      end
      
      # Run 0 (every hour)
      if run_count == 0
        # Nothing yet.
      end
      
      # 3 AM every day 
      if Time.now.hour == 4 # 3 AM
        db_server_id = ENV['RDS_DATABASE_ID']
        db_server = RDS.servers.get(db_server_id)
        if db_server.nil?
          puts "Could not find server #{db_server_id} to snapshot"
        end
        puts "Taking snapshot of #{db_server_id}..."
        snap_id = "#{db_server_id}-daily-snap-#{Time.now.strftime('%Y-%m-%d-%H-%M-%S')}"
        snapshot = db_server.snapshots.new(:id => snap_id).save
        puts "Requested snapshot #{snap_id}"
        
        daily_snaps = db_server.snapshots.find_all {|snap| snap.id =~ /.+-daily-snap-.+/ and snap.ready? }
        if daily_snaps.size > 40
          doomed_snap = daily_snaps.sort{ |x,y| x.created_at <=> y.created_at }.first
          "Pruning snapshot #{doomed_snap.id}, created at #{doomed_snap.created_at}"
          doomed_snap.destroy
        end
      end
    end
    
  end
end