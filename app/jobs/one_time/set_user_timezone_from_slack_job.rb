class OneTime::SetUserTimezoneFromSlackJob < ApplicationJob
  queue_as :default

  def perform
    User.where.not(slack_uid: nil).find_each(batch_size: 100) do |user|
      begin
        user_response = HTTP.auth("Bearer #{user.slack_access_token}")
          .get("https://slack.com/api/users.info?user=#{user.slack_uid}")

        user_data = JSON.parse(user_response.body.to_s)

        next unless user_data["ok"]

        timezone = user_data.dig("user", "tz")
        next unless timezone.present?

        # Convert IANA timezone to ActiveSupport timezone
        begin
          tz = ActiveSupport::TimeZone.find_tzinfo(timezone)
          user.update!(
            timezone: tz.name,
          )
          Rails.logger.info "Updated timezone for user #{user.id} to #{tz.name}"
        rescue TZInfo::InvalidTimezoneIdentifier => e
          Rails.logger.error "Invalid timezone #{timezone} for user #{user.id}: #{e.message}"
        end
      rescue => e
        Rails.logger.error "Failed to update timezone for user #{user.id}: #{e.message}"
      end
    end
  end
end
