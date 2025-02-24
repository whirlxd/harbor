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
    total_count = 0
    found_count = 0
    created_count = 0

    SailorsLog::SlackNotificationPreference.enabled.each do |preference|
      puts "Importing preference for #{preference.slack_user_id} in #{preference.slack_channel_id}"

      slnp = ::SailorsLogNotificationPreference.find_or_create_by(
        slack_uid: preference.slack_user_id,
        slack_channel_id: preference.slack_channel_id
      ) do |new_record|
        # This block only runs on creation, not when found
        created_count += 1
      end

      if slnp.persisted?
        found_count += 1
      else
        puts "Failed to create/find preference: #{slnp.errors.full_messages.join(', ')}"
      end

      total_count += 1
    end

    puts "Process complete:"
    puts "Total processed: #{total_count}"
    puts "Found existing: #{found_count}"
    puts "Newly created: #{created_count}"
    puts "Total in source: #{SailorsLog::SlackNotificationPreference.enabled.count}"
  end
end
