class SailorsLog::SlackNotificationPreference < ::ApplicationRecord
  self.abstract_class = true
  connects_to database: { reading: :sailors_log, writing: :sailors_log }
  self.table_name = "SlackNotificationPreference"

  scope :enabled, -> { where(enabled: true) }
end

class OneTime::ImportFromSailorsLogJob < ApplicationJob
  queue_as :default

  def perform
    # Import from SailorsLog
    SailorsLog::SlackNotificationPreference.enabled.each do |preference|
      slnp = ::SailorsLogNotificationPreference.find_or_create_by(
        slack_uid: preference.slack_user_id,
        slack_channel_id: preference.slack_channel_id
      )
    end
  end
end
