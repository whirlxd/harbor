Slack.configure do |config|
  config.token = ENV["SLACK_BOT_OAUTH_TOKEN"]  # Using the existing env variable name
end
