require 'httparty' 
class NewRelicClient
  include HTTParty

  format :xml

  def initialize(api_key, account_id, application_id)
    self.class.default_options = {:headers => {'x-api-key' => api_key}}
    self.class.base_uri "https://rpm.newrelic.com/accounts/#{account_id}/applications/#{application_id}/"
  end
  
# {"threshold_values"=>
#   [{"threshold_value"=>"2",
#     "name"=>"Apdex",
#     "end_time"=>"2011-05-27 18:35:59",
#     "begin_time"=>"2011-05-27 18:30:00",
#     "formatted_metric_value"=>"0.8 [0.5]",
#     "metric_value"=>"0.8"},
#    {"threshold_value"=>"1",
#     "name"=>"Application Busy",
#     "end_time"=>"2011-05-27 18:35:59",
#     "begin_time"=>"2011-05-27 18:30:00",
#     "formatted_metric_value"=>"21.8%",
#     "metric_value"=>"21.8"},
#    {"threshold_value"=>"1",
#     "name"=>"Error Rate",
#     "end_time"=>"2011-05-27 18:35:59",
#     "begin_time"=>"2011-05-27 18:30:00",
#     "formatted_metric_value"=>"0.18%",
#     "metric_value"=>"0.18"},
#    {"threshold_value"=>"1",
#     "name"=>"Throughput",
#     "end_time"=>"2011-05-27 18:35:59",
#     "begin_time"=>"2011-05-27 18:30:00",
#     "formatted_metric_value"=>"557 rpm",
#     "metric_value"=>"557"},
#    {"threshold_value"=>"1",
#     "name"=>"CPU",
#     "end_time"=>"2011-05-27 18:35:59",
#     "begin_time"=>"2011-05-27 18:30:00",
#     "formatted_metric_value"=>"67%",
#     "metric_value"=>"67"},
#    {"threshold_value"=>"1",
#     "name"=>"Response Time",
#     "end_time"=>"2011-05-27 18:35:59",
#     "begin_time"=>"2011-05-27 18:30:00",
#     "formatted_metric_value"=>"761 ms",
#     "metric_value"=>"761"},
#    {"threshold_value"=>"1",
#     "name"=>"Errors",
#     "end_time"=>"2011-05-27 18:35:59",
#     "begin_time"=>"2011-05-27 18:30:00",
#     "formatted_metric_value"=>"1.0 epm",
#     "metric_value"=>"1.0"},
#    {"threshold_value"=>"1",
#     "name"=>"Memory",
#     "end_time"=>"2011-05-27 18:35:59",
#     "begin_time"=>"2011-05-27 18:30:00",
#     "formatted_metric_value"=>"2375 MB",
#     "metric_value"=>"2375"},
#    {"threshold_value"=>"1",
#     "name"=>"DB",
#     "end_time"=>"2011-05-27 18:35:59",
#     "begin_time"=>"2011-05-27 18:30:00",
#     "formatted_metric_value"=>"43.4%",
#     "metric_value"=>"43.4"}]}
  def application_health
    health = self.class.get('/threshold_values.xml')
    return false unless health.is_a? Hash and Health.keys.size > 0
    
    return {
      :apdex                => health['threshold_values'][0]['metric_value'],
      :application_busy_pct => health['threshold_values'][1]['metric_value'],
      :error_pct            => health['threshold_values'][2]['metric_value'],
      :rpm                  => health['threshold_values'][3]['metric_value'],
      :cpu_time_pct         => health['threshold_values'][4]['metric_value'],
      :response_time_ms     => health['threshold_values'][5]['metric_value'],
      :epm                  => health['threshold_values'][6]['metric_value'],
      :memory_avg_mb        => health['threshold_values'][7]['metric_value'],
      :db_time_pct          => health['threshold_values'][8]['metric_value']
    }
  end
end