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

    case params[:command].gsub("/", "").downcase
    when "sailorslog"
      SlackCommand::SailorsLogJob.perform_later(params)
    when "timedump"
      SlackCommand::TimedumpJob.perform_later(params)
    end
  end

  private

  def verify_slack_request
    timestamp = request.headers["X-Slack-Request-Timestamp"]
    signature = request.headers["X-Slack-Signature"]

    # Skip verification in development
    return true if Rails.env.development?

    sig_basestring = "v0:#{timestamp}:#{request.raw_post}"

    # Try both signing secrets
    sailors_log_signature = "v0=" + OpenSSL::HMAC.hexdigest(
      "SHA256",
      ENV["SAILORS_LOG_SLACK_SIGNING_SECRET"],
      sig_basestring
    )

    harbor_signature = "v0=" + OpenSSL::HMAC.hexdigest(
      "SHA256",
      ENV["SLACK_SIGNING_SECRET"],
      sig_basestring
    )

    # Check if the request matches either signature
    unless ActiveSupport::SecurityUtils.secure_compare(sailors_log_signature, signature) ||
           ActiveSupport::SecurityUtils.secure_compare(harbor_signature, signature)
      head :unauthorized
      nil
    end
  end
end
