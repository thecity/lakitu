**Lakitu** lives in the cloud and rescues lost resque racers while throwing spinys at stale dynos.

He can:
  * Monitor a Resque queue backlog.
  * Make sure a set of Heroku config settings stay up to date.
  * Scale dynos based on data from NewRelic
  * Make sure a set of AWS servers are doing the right thing.
  * (maybe) check on a chef server.

Define these ENV vars (using _[heroku config ...](http://docs.heroku.com/config-vars)_) :

* HEROKU_USER

* HEROKU_PASS

* AWS_ACCESS_KEY_ID

* AWS_SECRET_ACCESS_KEY

* REDIS_URL

* NEW_RELIC_API_KEY

* NEW_RELIC_ID

* NEW_RELIC_APPID

This will give Lakitu access to both sides of the app and make sure they're in good shape.