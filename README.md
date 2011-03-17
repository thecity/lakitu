**Lakitu** lives in the cloud and rescues lost resque racers while throwing spinys at you when things go wrong.

He can:

* Monitor a Resque queue backlog.
* Make sure a set of Heroku config settings stay up to date.
<!-- * Scale dynos based on data from NewRelic -->
* Make sure a set of AWS servers are doing the right thing.
<!-- * (maybe) check on a chef server. -->
  
He will:

* Email you when things break. See lib/alert_mailer.rb

Define these ENV vars (using _[heroku config ...](http://docs.heroku.com/config-vars)_) :

* HEROKU_USER
* HEROKU_PASS
* HEROKU_APP (all for the app you want to monitor)
* AWS_ACCESS_KEY_ID
* AWS_SECRET_ACCESS_KEY 
* REDIS_MASTER_NAME - the EC2 Name tag of the Redis master server
* REDIS_SLAVE_NAME  - the EC2 Name tag of the Redis slave server
* MEMCACHED_NAME_PREFIX - the first part of the EC2 Name tags of your memcached servers

<!-- 
Not right now.
* NEW_RELIC_API_KEY
* NEW_RELIC_ID
* NEW_RELIC_APPID -->

This will give Lakitu access to both sides of the app and make sure they're in good shape.