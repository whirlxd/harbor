# Set priority for mailer jobs to be highest
ActionMailer::MailDeliveryJob.class_eval do
  self.priority = 0
end 