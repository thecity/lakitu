require 'mail'

class AlertMailer
  def self.deliver_alert(subject, body)
    mailer = AlertMailer.new
    mailer.setup
    mailer.deliver(subject, body)
  end

  def setup
    @to = ENV['ALERTS_EMAIL']
    @from = "#{ENV['HEROKU_APP']}-lakitu-alerts"
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