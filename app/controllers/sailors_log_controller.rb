class SailorsLogController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :verify_slack_request

  # Handle slack commands
  def create
    case params[:text].downcase.strip
    when "on"
      puts "Turning on notifications for #{params[:user_id]} in #{params[:channel_id]}"
      SailorsLogSetNotificationPrefJob.perform_later(params[:user_id], params[:channel_id], true)
      render json: {
        response_type: "in_channel",
        text: "@#{params[:user_name]} ran `/sailorslog on` to turn on High Seas notifications in this channel. Every time they code an hour on a project, a short message celebrating will be posted to this channel. They will also show on `/sailorslog leaderboard`."
      }
    when "off"
      SailorsLogSetNotificationPrefJob.perform_later(params[:user_id], params[:channel_id], false)
      render json: {
        response_type: "ephemeral",
        text: ":white_check_mark: Coding notifications have been turned off in this channel."
      }
    when "leaderboard"
      leaderboard = SailorsLog.generate_leaderboard(params[:channel_id])
      message = "*:boat: Sailor's Log - Today*"
      medals = [ "first_place_medal", "second_place_medal", "third_place_medal" ]
      # ex.
      # :first_place_medal: @Irtaza: 2h 6m → Farmworks [C#]: 125m
      # :second_place_medal: @Cigan: 1h 33m → Gitracker-1 [JAVA]: 49m + Dupe [JAVA]: 41m + Lovac-Integration [JAVA]: 2m
      leaderboard.each_with_index do |entry, index|
        medal = medals[index] || "white_small_square"
        message += "\n:#{medal}: `<@#{entry[:user_id]}>`: #{entry[:duration]} → "
        message += entry[:projects].map do |project|
          language = project[:language_emoji] ? "#{project[:language_emoji]} #{project[:language]}" : project[:language]
          "#{project[:name]} [#{language}]"
        end.join(" + ")
      end

      puts message
      render json: {
        response_type: "in_channel",
        text: message
      }
    else
      render json: {
        response_type: "ephemeral",
        text: "Available commands: `/sailorslog on`, `/sailorslog off`, `/sailorslog leaderboard`"
      }
    end
  end

  private

  def verify_slack_request
    timestamp = request.headers["X-Slack-Request-Timestamp"]
    signature = request.headers["X-Slack-Signature"]

    # Skip verification in development
    return true if Rails.env.development?

    slack_signing_secret = ENV["SLACK_SIGNING_SECRET"]
    sig_basestring = "v0:#{timestamp}:#{request.raw_post}"
    my_signature = "v0=" + OpenSSL::HMAC.hexdigest("SHA256", slack_signing_secret, sig_basestring)

    unless ActiveSupport::SecurityUtils.secure_compare(my_signature, signature)
      head :unauthorized
      nil
    end
  end
end
