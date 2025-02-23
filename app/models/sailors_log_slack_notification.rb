class SailorsLogSlackNotification < ApplicationRecord
  def notify_user!
    return if sent?

    SailorsLogNotifyJob.perform_now(self.id)
  end
end
