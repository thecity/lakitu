# Adapted from http://blog.darkhax.com/2010/07/30/auto-scale-your-resque-workers-on-heroku
require 'heroku'

module HerokuDynoAutoScale
  module Scaler
    class << self
      @@heroku = Heroku::Client.new(ENV['HEROKU_USER'], ENV['HEROKU_PASS'])

      def dynos
        @@heroku.info(ENV['HEROKU_APP'])[:dynos].to_i
      end

      def workers=(qty)
        @@heroku.set_dynos(ENV['HEROKU_APP'], qty)
      end

      def scaling_configuration=(scale_configuration)
        default_scaling = 
          [
            { :cpu => 0.01, :dynos => 1 },
            { :cpu => 0.10, :dynos => 3 },
            { :cpu => 0.5,  :dynos => 6 },
            { :cpu => 0.7,  :dynos => 10 },
          ]
        @@scale_configuration = scale_configuration || default_scaling
      end
      
      def scaling_configuration
        @@scale_configuration
      end
    end
  end
  

  def scale_dynos(cpu)
    Scaler.scale_configuration.reverse_each do |scale_info|
      # Run backwards so it gets set to the highest value first

      # If we have a cpu load greater than or equal to the dyno limit for our configuration
      if cpu >= scale_info[:cpu]
        # Set the number of workers unless they are already set to a level we want. 
        if Scaler.dynos <= scale_info[:dynos]
          Scaler.dynos = scale_info[:dynos]
          return scale_info[:dynos]
        end
      # Otherwise we have a cpu load lower than the upscale threshold 
      elsif cpu < scale_info[:cpu]
        if Scaler.dynos > scale_info[:dynos]
          Scaler.dynos = scale_info[:dynos]
          # Return here so we don't keep looping.
          # This will force dynos to only scale one increment every run.
          return scale_info[:dynos]
        end
      end
    end
  end
  
end