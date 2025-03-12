class Api::V1::HeartbeatsController < ApplicationController
  before_action :ensure_authenticated!

  def check
    # Check for heartbeats in the last 5 minutes
    recent_heartbeats = current_user.heartbeats
      .where("time > ?", 5.minutes.ago.to_f)
      .count

    render json: {
      received_heartbeats: recent_heartbeats > 0,
      count: recent_heartbeats,
      checked_at: Time.current
    }
  end

  private

  def ensure_authenticated!
    api_header = request.headers["Authorization"]
    raw_token = api_header&.split(" ")&.last
    header_type = api_header&.split(" ")&.first
    if header_type == "Bearer"
      api_token = raw_token
    elsif header_type == "Basic"
      api_token = Base64.decode64(raw_token)
    end
    return render json: { error: "Unauthorized" }, status: :unauthorized unless api_token.present?

    valid_key = ApiKey.find_by(token: api_token)
    return render json: { error: "Unauthorized" }, status: :unauthorized unless valid_key.present?

    @current_user = valid_key.user
    render json: { error: "Unauthorized" }, status: :unauthorized unless @current_user
  end

  def current_user
    @current_user
  end
end
