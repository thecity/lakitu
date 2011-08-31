RDS_BACKUP_QUEUE = GirlFriday::WorkQueue.new(:rds_backup_queue, :size => 1) do |msg|
  rds = Fog::AWS::RDS.new( 
              :aws_access_key_id => ENV['AWS_ACCESS_KEY_ID'],
              :aws_secret_access_key => ENV['AWS_SECRET_ACCESS_KEY'])
              
  db_server_id = ENV['RDS_DATABASE_ID']
  db_server = rds.servers.get(db_server_id)
  if db_server.nil?
    puts "Could not find server #{db_server_id} to snapshot"
  end
  puts "Taking snapshot of #{db_server_id}..."
  snap_id = "#{db_server_id}-daily-snap-#{Time.now.strftime('%Y-%m-%d-%H-%M-%S')}"
  snapshot = db_server.snapshots.new(:id => snap_id).save
  puts "Requested snapshot #{snap_id}"
  
  daily_snaps = db_server.snapshots.find_all {|snap| snap.id =~ /.+-daily-snap-.+/ and snap.ready? }
  if daily_snaps.size > 10
    doomed_snap = daily_snaps.sort{ |x,y| x.created_at <=> y.created_at }.first
    "Pruning snapshot #{doomed_snap.id}, created at #{doomed_snap.created_at}"
    doomed_snap.destroy
  end
end