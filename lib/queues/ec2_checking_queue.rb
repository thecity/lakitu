EC2_CHECKING_QUEUE = GirlFriday::WorkQueue.new(:ec2_queue, :size => 2) do |msg|
  puts 'Checking EC2 servers'
  # Check on our EC2 services.
  heroku_config = Heroku::Client.new(ENV['HEROKU_USER'], ENV['HEROKU_PASS']).config_vars(ENV['HEROKU_APP'])
  ec2 = Fog::Compute.new(
              :provider => 'AWS', 
              :aws_access_key_id => ENV['AWS_ACCESS_KEY_ID'],
              :aws_secret_access_key => ENV['AWS_SECRET_ACCESS_KEY'])
  
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
  memcached_servers     = ec2.servers.find_all {|server| server.tags['Name'].include?(ENV['MEMCACHED_NAME_PREFIX']) }
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