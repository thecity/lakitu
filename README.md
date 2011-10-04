**Lakitu** lives in the cloud and throws emails at you when things go wrong.

He can:

* Monitor a Resque queue backlog.
* Make sure a set of Heroku config settings stay up to date.
* Scale resque workers based on queue size.
* Make sure a set of memcached servers are up.
  
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

The URL of your Redis server that backs your Resque workers.

* REDIS_URL

Sendgrid credentials to deliver alerts.

* SENDGRID_USERNAME
* SENDGRID_PASSWORD
* SENDGRID_DOMAIN

The email addresses to deliver alerts to, comma-separated.

* ALERTS_EMAIL

