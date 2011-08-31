require 'mail'

class AlertMailer
  def self.deliver_alert(subject, body)
    mailer = AlertMailer.new
    mailer.setup
    mailer.deliver(subject, body)
  end

  def setup
    @to = 'notifications@onthecity.org'
    @cc = ''                       # 'sev2@thecity.pagerduty.com'
    @from = "#{HEROKU_APP}-lakitu-alerts"
  end
    
  def deliver(subject, body)
    mail         = Mail.new
    mail.to      = @to
    mail.cc      = @cc
    mail.from    = @from
    mail.subject = subject
    mail.body    = body

    mail.deliver!
  end
end