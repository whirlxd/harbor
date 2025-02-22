class SailorsLogSlackNotification < ApplicationRecord
  after_create :notify_user

  private

  def notify_user
    return if sent?

    SailorsLogSlackNotificationJob.perform_later(self)
  end
end
