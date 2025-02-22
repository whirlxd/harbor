class SailorsLogSlackNotificationJob < ApplicationJob
  queue_as :default

  def perform(sailors_log_slack_notification)
    slack_uid = sailors_log_slack_notification.slack_uid
    slack_channel_id = sailors_log_slack_notification.slack_channel_id
    project_name = sailors_log_slack_notification.project_name
    project_duration = sailors_log_slack_notification.project_duration

    kudos_message = [
      "Great work!",
      "Nice job!",
      "Amazing!",
      "Fantastic!",
      "Excellent!",
      "Awesome!",
      "Well done!",
      "Wahoo!",
      "Way to go!"
    ].sample

    hours = project_duration / 3600

    message = ":boat: <@#{slack_uid}> just coded 1 more hour on #{project_name} (total: #{hours}hrs). #{kudos_message}"

    response = HTTP.auth("Bearer #{ENV['SLACK_BOT_TOKEN']}")
      .post("https://slack.com/api/chat.postMessage",
            json: {
              channel: slack_channel_id,
              text: message
            })

    response_data = JSON.parse(response.body)
    if response_data["ok"]
      sailors_log_slack_notification.update(sent: true)
    else
      Rails.logger.error("Failed to send Slack notification: #{response_data["error"]}")
    end
  end
end
