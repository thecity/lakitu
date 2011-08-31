WORKER_SCALING_QUEUE = GirlFriday::WorkQueue.new(:worker_scaling, :size => 1) do |msg|
  puts "Scaling workers..."
  workers = HerokuResqueScaler::Scaler.scale_workers
  puts "#{HerokuResqueScaler::Scaler.job_count} jobs, #{workers} workers."
end