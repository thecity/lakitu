**Lakitu** lives in the cloud and rescues lost resque racers while throwing spinys at you when things go wrong.

He can:

* Monitor a Resque queue backlog.
* Make sure a set of Heroku config settings stay up to date.
* Scale dynos based on data from NewRelic
* Make sure a set of AWS servers are doing the right thing.
  
He will:

* Email you when things break. See lib/alert_mailer.rb

Define these ENV vars (using _[heroku config ...](http://docs.heroku.com/config-vars)_) :

* HEROKU_USER
* HEROKU_PASS
* HEROKU_APP 

* AWS_ACCESS_KEY_ID
* AWS_SECRET_ACCESS_KEY 

* NEW_RELIC_API_KEY
* NEW_RELIC_ID
* NEW_RELIC_APPID 

* MEMCACHED_NAME_PREFIX - the first part of the EC2 Name tags of your memcached servers
* REDIS_URL - the URL of your redis server

This will give Lakitu access to both sides of the app and make sure they're in good shape.

Your production app should store its memcached server list in a comma-separated string of IPs in ENV['MEMCACHE_SERVERS']