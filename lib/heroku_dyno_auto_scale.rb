# Adapted from http://blog.darkhax.com/2010/07/30/auto-scale-your-resque-workers-on-heroku
require 'heroku'

module HerokuDynoAutoScale
  class Scaler
    class << self
      @@heroku = Heroku::Client.new(ENV['HEROKU_USER'], ENV['HEROKU_PASS'])

      def dynos
        @@heroku.info(ENV['HEROKU_APP'])[:dynos].to_i
      end

      def dynos=(qty)
        @@heroku.set_dynos(ENV['HEROKU_APP'], qty)
      end

      def scaling_configuration=(scale_configuration)
        default_scaling = 
          [
            { :rpm => 100,  :dynos => 10 },
            { :rpm => 200,  :dynos => 15 },
            { :rpm => 500,  :dynos => 20 },
            { :rpm => 1000, :dynos => 30 },
          ]
        @@scale_configuration = scale_configuration || default_scaling
      end
      
      def scaling_configuration
        @@scale_configuration
      end
      
      def scale_dynos(rpm)
        self.scaling_configuration.reverse_each do |scale_info|
          # Run backwards so it gets set to the highest value first

          # If we have an rpm  greater than or equal to the dyno limit for our configuration
          if rpm >= scale_info[:rpm]
            # Set the number of workers unless they are already set to a level we want. 
            if self.dynos <= scale_info[:dynos]
              self.dynos = scale_info[:dynos]
              return scale_info[:dynos]
            end
          # Otherwise we have a rpm lower than the upscale threshold 
          elsif rpm < scale_info[:rpm]
            if self.dynos > scale_info[:dynos]
              self.dynos = scale_info[:dynos]
              # Return here so we don't keep looping.
              # This will force dynos to only scale one increment every run.
              return scale_info[:dynos]
            end
          end
        end
      end
      
    end
  end
end