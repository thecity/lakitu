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
      
      def default_scaling
        [
          { :rpm_range => 0..200,       :dynos => 10 },
          { :rpm_range => 201..500,     :dynos => 15 },
          { :rpm_range => 501..1000,    :dynos => 20 },
          { :rpm_range => 1001..20_000, :dynos => 30 },
        ]
      end

      def scaling_configuration=(scale_configuration)
        @@scale_configuration = scale_configuration || default_scaling
      end
      
      def scaling_configuration
        @@scale_configuration || default_scaling
      end
      
      def scale_dynos(rpm)
        dynos = self.dynos
        
        # Run backwards so it gets set to the highest value first
        self.scaling_configuration.reverse_each do |scale_info|
          # If our rpm is within this range
          if scale_info[:rpm_range].include?(rpm) 
            # and we don't have the right number of dynos
            if dynos != scale_info[:dynos]
              # change the dynos to match
              self.dynos = scale_info[:dynos]
              return scale_info[:dynos]
            else
              # we're already set
              return dynos
            end
          end
        end  
        
        # We didn't return from the scaling loop - this is a problem.
        AlertMailer.deliver_alert("New Relic Alert - RPM out of range", 
          "Heroku Severity 2:\n\n New Relic reported RPM of #{rpm}, which was larger than the configured maximum\
          of #{self.scaling_configuration.last[:rpm_range].max}")
          
      end
    end
  end
end