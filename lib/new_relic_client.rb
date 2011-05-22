require 'httparty' 
class NewRelicClient
  include HTTParty

  format :xml

  def initialize(api_key, account_id, application_id)
    self.class.default_options = {:headers => {'api_key' => api_key}}
    self.class.base_uri "https://rpm.newrelic.com/accounts/#{account_id}/applications/#{application_id}/"
  end
  
# {"threshold_values"=>
#   [{"name"=>"Apdex",
#     "threshold_value"=>"0",
#     "end_time"=>"2011-03-10 18:42:00",
#     "begin_time"=>"2011-03-10 18:36:00",
#     "formatted_metric_value"=>"NS [0.5]*",
#     "metric_value"=>""},
#    {"name"=>"Throughput",
#     "threshold_value"=>"1",
#     "end_time"=>"2011-03-10 18:42:00",
#     "begin_time"=>"2011-03-10 18:36:00",
#     "formatted_metric_value"=>"0.0 rpm",
#     "metric_value"=>"0.0"},
#    {"name"=>"CPU",
#     "threshold_value"=>"1",
#     "end_time"=>"2011-03-10 18:41:59",
#     "begin_time"=>"2011-03-10 18:36:00",
#     "formatted_metric_value"=>"0.01%",
#     "metric_value"=>"0.01"},
#    {"name"=>"Response Time",
#     "threshold_value"=>"1",
#     "end_time"=>"2011-03-10 18:42:00",
#     "begin_time"=>"2011-03-10 18:36:00",
#     "formatted_metric_value"=>"0 ms",
#     "metric_value"=>"0"},
#    {"name"=>"Memory",
#     "threshold_value"=>"1",
#     "end_time"=>"2011-03-10 18:41:59",
#     "begin_time"=>"2011-03-10 18:36:00",
#     "formatted_metric_value"=>"318 MB",
#     "metric_value"=>"318"},
#    {"name"=>"DB",
#     "threshold_value"=>"1",
#     "end_time"=>"2011-03-10 18:42:00",
#     "begin_time"=>"2011-03-10 18:36:00",
#     "formatted_metric_value"=>"0.0%",
#     "metric_value"=>"0.0"}]}
  def application_health
    health = self.class.get('/threshold_values.xml')
    return false unless health.is_a? Hash
    
    apdex         = health['threshold_values'][0]['metric_value']
    throughput    = health['threshold_values'][1]['metric_value']
    cpu           = health['threshold_values'][2]['metric_value']
    response_time = health['threshold_values'][3]['metric_value']
    
    return {:apdex => apdex, :throughput => throughput, :response_time => response_time, :cpu => cpu}
  end
end