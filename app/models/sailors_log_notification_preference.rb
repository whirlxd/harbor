class SailorsLogNotificationPreference < ApplicationRecord
  after_create :ensure_sailors_log_exists

  belongs_to :sailors_log,
             class_name: "SailorsLog",
             foreign_key: :slack_uid,
             primary_key: :slack_uid,
             optional: true
  private

  def ensure_sailors_log_exists
    SailorsLog.find_or_create_by(slack_uid: slack_uid)
  end
end
