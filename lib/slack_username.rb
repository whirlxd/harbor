class SlackUsername
  def self.find_by_uid(uid)
    cached_name = Rails.cache.fetch("slack_username_#{uid}", expires_in: 1.day) do
      response = HTTP.headers(Authorization: "Bearer #{ENV.fetch("SAILORS_LOG_SLACK_BOT_OAUTH_TOKEN")}").get("https://slack.com/api/users.info?user=#{uid}")
      data = JSON.parse(response.body)
      data.dig("user", "profile", "display_name_normalized") || nil
    end

    cached_name
  end
end
