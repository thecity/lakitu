# A Resque plugin that will increase workers until the queue is empty.
# Adapted from http://blog.darkhax.com/2010/07/30/auto-scale-your-resque-workers-on-heroku

module HerokuResqueScaler
  class Scaler
    class << self
      @@heroku = Heroku::Client.new(ENV['HEROKU_USER'], ENV['HEROKU_PASS'])
      
      def workers
        # Seems like I only care about how many workers are reporting.
        # But we'll see.
        # if self.should_scale_workers?
          # @@heroku.info(ENV['HEROKU_APP'])[:workers].to_i
        # else
          Resque.info[:workers].to_i          
        # end
      end

      def workers=(qty)
        if self.should_scale_workers? 
          puts "Scaling Heroku workers to #{qty}"
          @@heroku.set_workers(ENV['HEROKU_APP'], qty)
        else
          puts "Would scale workers to #{qty}..."
        end
      end

      def job_count
        Resque.info[:pending].to_i + Resque.info[:working].to_i
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
  
      def scaling_configuration
        @@scale_configuration
      end
  
      def should_scale_workers?
        ['production', 'staging'].include?(ENV['RACK_ENV'])
      end
      
      
      def scale_workers
        # Nothing fancy, just trim back to the minimum workers if there's no jobs
        return self.workers = self.scaling_configuration.first[:workers]  if self.job_count.zero?

        self.scaling_configuration.reverse_each do |scale_info|
          # Run backwards so it gets set to the highest value first
          # Otherwise if there were 70 jobs, it would get set to 1, then 2, then 3, etc

          # If we have a job count greater than or equal to the job limit for this scale info
          if self.job_count >= scale_info[:job_count]
            # Set the number of workers unless they are already set to a level we want. Don't scale down here!
            if self.workers <= scale_info[:workers]
              self.workers = scale_info[:workers]
            end
            return self.scale_info[:workers] # We've set or ensured that the worker count is high enough
          # Otherwise just return the number of workers
          else
            return self.workers
          end
        end
        
      end
    end
  end
end