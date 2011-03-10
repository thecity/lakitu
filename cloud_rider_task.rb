namespace 'lakitu' do
  desc 'Scale and check the city app stack'
  task :cloud_rider do
    puts "Starting Lakitu"
    
    while true
      puts 'sleeping...'
      sleep 5 * 60 # 5 minute sample time
      run_count = run_count % 12 # One hour worth of intervals you can check
      
      # Run 1, 2, 3, 4 ... (every 5 minutes)
      health = NEWRELIC.application_health
      if health
        dynos = HerokuDynoAutoScale::Scaler.scale_dynos(health[:cpu])
      end
      
      # Run 0, 2, 3, 4, ... (every 10 minutes)
      if run_count % 2 == 0
        
      # Run 3, 6, 9, ... (every 15 minutes)
      elsif run_count % 3 == 0
        # Check the resque queue size and connectivity
        begin
          queue_size = Resque.info[:pending].to_i
          if queue_size >= RESQUE_QUEUE_LIMIT
            InstantMailer.deliver_resque_error_notification(queue_size, nil)
          end
        rescue Errno::ECONNREFUSED => e
          InstantMailer.deliver_resque_error_notification('ERROR', 'ERROR', e)
        end
      
      # Run 4, 8, 12 ... (every 20 minutes)
      elsif run_count % 4 == 0
        
      # Run 5, 10 ... (every 25 minutes)
      elsif run_count % 5 == 0
        
      end
    end
    
  end
end
