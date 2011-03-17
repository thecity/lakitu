namespace 'lakitu' do
  desc 'Scale and check the city app stack'
  task :cloud_rider do
    puts "Starting Lakitu"
    
    while true
      puts 'sleeping...'
      sleep 1 * 60 # 1 minute sample time
      run_count = (run_count + 1) % 60 # One hour worth of 1-minute intervals (0-59) you can check
      
      puts "Run number #{run_count}"
      
      # Run 1, 2, 3, 4... (every minute)
      HerokuResqueAutoScale::Scaler.scale_workers(Resque.info[:pending].to_i)
      
      # Run 0, 5, 10, 15... (every 5 minutes)
      if run_count % 5 == 0
        if (health = NEWRELIC.application_health).present?
          dynos = HerokuDynoAutoScale::Scaler.scale_dynos(health[:cpu])
        end
      # Run 0, 10, 20, 30, 40, 50 (every 10 minutes)        
      elsif run_count % 10 == 0
        # Nothing yet.
      # Run 0, 15, 30, 45 (every 15 minutes)
      elsif run_count % 15 == 0
        # Check the resque queue size and redis connectivity
        is_error   = false
        queue_size = 0
        begin
          queue_size = Resque.info[:pending].to_i
          workers    = Resque.info[:workers].to_i
          
          if queue_size >= RESQUE_QUEUE_LIMIT or workers == 0
             Mail.deliver do 
               to 'jonathan@onthecity.org'
               # to 'notifications@onthecity.org'
               # cc 'sev2@thecity.pagerduty.com'
               from 'resque-alerts@onthecity.org'
               subject "Resque alert in #{ENV['RACK_ENV']}"
               body "Resque Severity 2:\n\n Queue size: #{queue_size}, expected <= #{RESQUE_QUEUE_LIMIT}\n\n Workers #{workers}, expected > 0.\n\n"
             end
          end
        rescue Errno::ECONNREFUSED => e
          Mail.deliver do 
            to 'jonathan@onthecity.org'
            # to 'notifications@onthecity.org'
            # cc 'sev2@thecity.pagerduty.com'
            from 'resque-alerts@onthecity.org'
            subject "Resque ERROR in #{ENV['RACK_ENV']}"
            body "Resque cannot communicate with Redis. This is bad!"
          end
        end
      # Run 0, 20, 40 (every 20 minutes)
      elsif run_count % 20 == 0
        # Nothing yet.
      # Run 5, 10 ... (every 25 minutes)
      elsif run_count > 0 and run_count % 5 == 0
        # Nothing yet.
      # Run 0 (every hour)
      elsif run_count == 0
        Resque.redis.bgrewriteaof
      end
    end
    
  end
end
