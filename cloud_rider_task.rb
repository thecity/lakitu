namespace 'lakitu' do
  desc 'Scale and check the city app stack'
  task :cloud_rider do
    puts "Starting Lakitu"
    run_count = 0
    while true
      puts 'sleeping...'
      sleep 5 * 60 # 5 minute sample time
      run_count = (run_count + 1) % 60 # One hour worth of 5-minute intervals (0-55) you can check
      
      puts "Run number #{run_count}"
      
      # Run 0, 5, 10, 15... (every 5 minutes)
      if run_count % 5 == 0
        # Scale the dynos based CPU load
        if (health = NEWRELIC.application_health).present?
          dynos = HerokuDynoAutoScale::Scaler.scale_dynos(health[:cpu])
        end
      # Run 0, 10, 20, 30, 40, 50 (every 10 minutes)        
      elsif run_count % 10 == 0
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
        dead_memcached_server = EC2.servers.find_all {|server| server.tags['Name'].include?(ENV['MEMCACHED_NAME_PREFIX']) }.detect(false) { |server| !server.ready? }
        unless dead_memcached_server
          AlertMailer.deliver_alert("Memcached alert - server down", 
            "Memcached Severity 2:\n\n Memcached server #{redis_server.id} is DOWN.") 
        end
        
        # Site memcached server list should contain only listed servers
        memcached_addresses  = EC2.servers.find_all {|server| server.tags['Name'].include?(ENV['MEMCACHED_NAME_PREFIX']) }.collect{|server| server.private_dns_name }
        if !heroku_config['MEMCACHED_SERVERS'].split(',').to_set.subset?(memcached_addresses.to_set)
          AlertMailer.deliver_alert("Memcached alert - server misconfigured.", 
            "Memcached Severity 2:\n\n Memcached server addresses of #{memcached_addresses.join(',')} does not match #{heroku_config['MEMCACHED_SERVERS']} in #{ENV['HEROKU_APP']}.")
        end
        
      # Run 0, 15, 30, 45 (every 15 minutes)
      elsif run_count % 15 == 0
        # Check the resque queue size and, implicitly, redis connectivity
        is_error   = false
        queue_size = 0
        begin
          queue_size = Resque.info[:pending].to_i
          workers    = Resque.info[:workers].to_i
          
          if queue_size >= RESQUE_QUEUE_LIMIT or workers == 0
            AlertMailer.deliver_alert("Resque queue size alert", 
              "Resque Severity 2:\n\n Queue size: #{queue_size}, expected < #{RESQUE_QUEUE_LIMIT}\n\n Workers #{workers}, expected > 0.\n\n")
          end
        rescue Errno::ECONNREFUSED => e
          AlertMailer.deliver_alert("Resque connectivity error", 
            "Resque severity 2:\n\n Resque cannot communicate with Redis. This is bad!")
        end
      # Run 0, 20, 40 (every 20 minutes)
      elsif run_count % 20 == 0
        # Nothing yet.
      # Run 5, 10 ... (every 25 minutes)
      elsif run_count > 0 and run_count % 5 == 0
        # Nothing yet.
      # Run 0 (every hour)
      elsif run_count == 0
      end
    end
    
  end
end
