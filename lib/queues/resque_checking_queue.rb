RESQUE_CHECKING_QUEUE = GirlFriday::WorkQueue.new(:resque_checker, :size => 1) do |msg|
  puts "Checking Resque"
  Resque.redis           = ENV['REDIS_URL']
  Resque.redis.namespace = ENV['REDIS_NAMESPACE']
  
  # Check the resque queue size and, implicitly, redis connectivity
  is_error   = false
  queue_size = 0
  begin
    queue_size = Resque.info[:pending].to_i
    # this should really check heroku
    workers    = Resque.info[:workers].to_i

    if queue_size >= RESQUE_QUEUE_LIMIT
      puts "Queue size error: Queue size: #{queue_size}, " + \
            "expected < #{RESQUE_QUEUE_LIMIT}"
      AlertMailer.deliver_alert("Resque queue size alert", 
        "Resque Severity 2:\n\n " + \
        "Queue size: #{queue_size}, expected < #{RESQUE_QUEUE_LIMIT}\n")
    elsif workers == 0
      puts "Worker error: Workers #{workers}, expected > 0"
      AlertMailer.deliver_alert("Resque worker alert", 
        "Resque Severity 2:\n\n " + \
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