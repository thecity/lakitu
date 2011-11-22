REDIS_CHECKING_QUEUE = GirlFriday::WorkQueue.new(:redis_checker, :size => 1) do |msg|
  puts "Checking redis"
  
  check_servers = ENV['REDIS_SERVER_URLS'].split(',')
  cfg_cmds      = ENV['REDIS_CONFIG_CMDS'] ? ENV['REDIS_CONFIG_CMDS'].split(',') : [].tap {|cfg| check_servers.count.times { cfg << 'config' }}
  
  if check_servers.count != cfg_cmds.count
    AlertMailer.deliver_alert(
      'Redis checking misconfigured',
      "Redis check configuration is incorrect - #{check_servers.count} servers specified but #{cfg_cmds.count} configuration commands were given."
    )
  else
    check_servers.each_with_index do |redis_server_url, i|
      begin
        puts "Checking Redis server #{redis_server_url}..."
        server = Redis.connect(:url => redis_server_url)
        # redistogo renames config to some obscure sha1, so we have to send it via method_missing
        max_memory  = server.send(cfg_cmds[i], :get, 'maxmemory').last.to_f
        used_memory = server.info['used_memory'].to_f
      
        used_pct = max_memory.zero? ? 0 : ((used_memory / max_memory)*100).ceil
        puts "#{redis_server_url} - #{used_pct}% memory used"

        if used_pct > ENV['REDIS_MEMORY_THRESHOLD'].to_i
          AlertMailer.deliver_alert(
            'Redis memory threshold exceeded',
            "Redis server #{redis_server_url} has exceeded #{ENV['REDIS_MEMORY_THRESHOLD']}% of memory usage, with #{used_pct}% used."
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
end