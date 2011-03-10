# Adapted from http://blog.darkhax.com/2010/07/30/auto-scale-your-resque-workers-on-heroku
require 'heroku'

module HerokuResqueAutoScale
  module Scaler
    class << self
      @@heroku = Heroku::Client.new(ENV['HEROKU_USER'], ENV['HEROKU_PASS'])

      def workers
        @@heroku.info(ENV['HEROKU_APP'])[:workers].to_i
      end

      def workers=(qty)
        @@heroku.set_workers(ENV['HEROKU_APP'], qty)
      end

      def job_count
        Resque.info[:pending].to_i
      end
      
      def scaling_configuration=(scale_configuration)
        default_scaling = 
          [
            { :workers => 1,  :job_count => 0  },
            { :workers => 3,  :job_count => 25 },
            { :workers => 5,  :job_count => 60 },
            { :workers => 8,  :job_count => 80 },
            { :workers => 10, :job_count => 100 },
            { :workers => 15, :job_count => 150 },
            { :workers => 20, :job_count => 200 }
          ]
        @@scale_configuration = scale_configuration || default_scaling
      end
  end
  

  def after_perform_scale_down(*args)
    # Nothing fancy, just shut everything down if we have no jobs
    Scaler.workers = 0 if Scaler.job_count.zero?
  end

  def after_enqueue_scale_up(*args)
    @@scale_configuration.reverse_each do |scale_info|
      # Run backwards so it gets set to the highest value first
      # Otherwise if there were 70 jobs, it would get set to 1, then 2, then 3, etc

      # If we have a job count greater than or equal to the job limit for our configuration
      if Scaler.job_count >= scale_info[:job_count]
        # Set the number of workers unless they are already set to a level we want. Don't scale down here!
        if Scaler.workers <= scale_info[:workers]
          Scaler.workers = scale_info[:workers]
        end
        break # We've set or ensured that the worker count is high enough
      end
      
    end
  end
  
end

