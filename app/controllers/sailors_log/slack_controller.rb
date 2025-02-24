class SailorsLog::SlackController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :verify_slack_request

  # allow usage of short_time_simple
  include ApplicationHelper
  helper_method :short_time_simple

  # Handle slack commands
  def create
    # Acknowledge receipt
    render json: {
      response_type: "ephemeral",
      blocks: [
        {
          type: "context",
          elements: [
            {
              type: "mrkdwn",
              text: "#{params[:command]} #{params[:text]}"
            }
          ]
        }
      ]
    }

    case params[:text].downcase.strip
    when "on", "off"
      SlackCommand::SailorsLogOnOffJob.perform_later(
        params[:user_id],
        params[:channel_id],
        params[:user_name],
        params[:response_url],
        params[:text].downcase.strip == "on",
      )
    when "leaderboard"
      # Process in background
      SlackCommand::SailorsLogLeaderboardJob.perform_later(
        params[:user_id],
        params[:channel_id],
        params[:response_url],
      )
    else
      SlackCommand::SailorsLogHelpJob.perform_later(
        params[:response_url],
      )
    end
  end

  private

  def verify_slack_request
    timestamp = request.headers["X-Slack-Request-Timestamp"]
    signature = request.headers["X-Slack-Signature"]

    # Skip verification in development
    return true if Rails.env.development?

    slack_signing_secret = ENV["SAILORS_LOG_SLACK_SIGNING_SECRET"]
    sig_basestring = "v0:#{timestamp}:#{request.raw_post}"
    my_signature = "v0=" + OpenSSL::HMAC.hexdigest("SHA256", slack_signing_secret, sig_basestring)

    unless ActiveSupport::SecurityUtils.secure_compare(my_signature, signature)
      head :unauthorized
      nil
    end
  end
end
