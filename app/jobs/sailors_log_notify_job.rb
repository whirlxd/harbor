class SailorsLogNotifyJob < ApplicationJob
  queue_as :default

  def perform(sailors_log_slack_notification_id)
    slsn = SailorsLogSlackNotification.find(sailors_log_slack_notification_id)

    slack_uid = slsn.slack_uid
    slack_channel_id = slsn.slack_channel_id
    project_name = slsn.project_name
    project_duration = slsn.project_duration

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

    message = ":boat: <@#{slack_uid}> just coded 1 more hour on *#{project_name}* (total: #{hours}hrs). _#{kudos_message}_"

    response = HTTP.auth("Bearer #{ENV['SLACK_BOT_OAUTH_TOKEN']}")
      .post("https://slack.com/api/chat.postMessage",
            json: {
              channel: slack_channel_id,
              text: message
            })

    response_data = JSON.parse(response.body)
    if response_data["ok"]
      slsn.update(sent: true)
    else
      Rails.logger.error("Failed to send Slack notification: #{response_data["error"]}")
      throw "Failed to send Slack notification: #{response_data["error"]}"
    end
  end
end
