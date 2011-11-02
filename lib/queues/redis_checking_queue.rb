REDIS_CHECKING_QUEUE = GirlFriday::WorkQueue.new(:redis_checker, :size => 1) do |msg|
  puts "Checking redis"
  check_servers = ENV['REDIS_SERVERS'].split(',')
  check_servers.each do |redis_server_url|
    begin
      server = Redis.new(redis_server_url)
      max_memory  = server.config(:get, 'maxmemory')['maxmemory'].to_f
      used_memory = server.info['used_memory'].to_f
      
      used_pct = max_memory.zero? ? 0 : ((used_memory / max_memory)*100).ceil

      if used_pct > REDIS_MEMORY_THRESHOLD
        AlertMailer.deliver_alert(
          'Redis memory threshold exceeded',
          "Redis server #{redis_server_url} has exceeded #{REDIS_MEMORY_THRESHOLD}% of memory usage, with #{used_pct}% used."
        )
      end
      
    rescue Exception => e
      AlertMailer.deliver_alert(
        'Exception encountered checking redis',
        "Exception encountered when checking #{redis_server_url}: #{e}\nBacktrace:\n#{e.backtrace}"
      )
    end
  end
end