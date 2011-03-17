class AlertMailer
  def self.deliver_alert(subject, body)
    mailer = AlertMailer.new
    mailer.setup
    mailer.deliver(subject, body)
  end

  def setup
    @to = 'jonathan@onthecity.org' # 'notifications@onthecity.org'
    @cc = ''                       # 'sev2@thecity.pagerduty.com'
    @from = 'lakitu-alerts@onthecity.org'
  end
    
  def deliver(subject, body)
    Mail.deliver do
      to @to
      cc @cc
      from @from
      subject subject
      body body
    end
  end
end