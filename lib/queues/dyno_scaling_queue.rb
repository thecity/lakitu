# Disabled.
DYNO_SCALING_QUEUE = GirlFriday::WorkQueue.new(:dyno_scaling_queue, :size => 1) do |msg|
  puts "Dyno scaling disabled."
  puts 'Scaling dynos...'
  # Scale the dynos based on RPM
  if health = NewRelicClient.new(ENV['NEW_RELIC_API_KEY'], ENV['NEW_RELIC_ID'], ENV['NEW_RELIC_APPID']).application_health
    dynos = HerokuDynoAutoScale::Scaler.scale_dynos(health[:rpm].to_i)
    puts "New Relic reported RPM of #{health[:rpm]}, dynos set to #{dynos}"
  else
    puts "New Relic failed to deliver application health in a timely manner :("
  end
end