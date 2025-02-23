class SailorsLogLeaderboardJob < ApplicationJob
  queue_as :default
  include ApplicationHelper

  def perform(channel_id, slack_uid, response_url)
    puts "Performing leaderboard job for channel #{channel_id} and user #{slack_uid}"
    # either find a leaderboard for this channel from the last 1 minute or create a new one
    leaderboard = SailorsLogLeaderboard.where(slack_channel_id: channel_id, deleted_at: nil)
                                       .where("created_at > ?", 1.minute.ago)
                                       .order(created_at: :desc)
                                       .first

    # Create new leaderboard if none found
    leaderboard ||= SailorsLogLeaderboard.create!(
      slack_channel_id: channel_id,
      slack_uid: slack_uid
    )

    # Update with final message
    response = HTTP.post(response_url, json: {
      response_type: "in_channel",
      replace_original: true,
      text: leaderboard.message
    })

    puts "Response: #{response.body}"
  end
end
