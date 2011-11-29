**Lakitu** lives in the cloud and throws emails at you when things go wrong.

He can:

* Monitor a Resque queue backlog.
* Make sure a set of Heroku config settings stay up to date.
* Scale resque workers based on queue size.
* Monitor the memory usage and uptime of a set of Redis servers.
* Make sure a set of EC2-based memcached servers are up.
* Take an RDS snapshot every so often.
  
He will:

* Email you when things break. See lib/alert_mailer.rb

Define these ENV vars (using _[heroku config ...](http://docs.heroku.com/config-vars)_) :

The credentials for the Heroku application you're monitoring.

* HEROKU_USER
* HEROKU_PASS
* HEROKU_APP 

The AWS credentials for the EC2 servers backing your application.

* AWS_ACCESS_KEY_ID
* AWS_SECRET_ACCESS_KEY 

The prefix of the EC2 Name tags of your memcached servers. Your production Heroku app should store its memcached server list in a comma-separated string of IPs in ENV['MEMCACHE_SERVERS']. 

* MEMCACHED_NAME_PREFIX

The URL of your Redis server that backs your Resque workers, and the namespace of the Resque data. Optionally, a queue size threshold to monitor.

* RESQUE_REDIS_URL
* RESQUE_NAMESPACE
* RESQUE_QUEUE_LIMIT

The comma-separated URLs of any other Redis servers you wish to monitor. Optionally, custom configuration commands for each server. 
Example:

    REDIS_SERVER_URLS: "redis://username:password@pike.redistogo.com:5044,redis://ip-10-114-119-41.ec2.internal"
    REDIS_CONFIG_CMDS: "a2352352365f,config"

* REDIS_SERVER_URLS
* REDIS_CONFIFG_CMDS

The database ID of the RDS server you'd like to snapshot. 10 rolling snapshots will be retained.

* RDS_DATABASE_ID

Sendgrid credentials to deliver alerts.

* SENDGRID_USERNAME
* SENDGRID_PASSWORD
* SENDGRID_DOMAIN

The email addresses to deliver alerts to, comma-separated.

* ALERTS_EMAIL

