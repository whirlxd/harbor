class SailorsLogSlackNotification < ApplicationRecord
  after_create :notify_user

  private

  def notify_user
    return if sent?

    SailorsLogNotifyJob.perform_later(self.id)
  end
end
