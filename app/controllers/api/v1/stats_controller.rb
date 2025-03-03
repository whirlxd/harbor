class Api::V1::StatsController < ApplicationController
  before_action :ensure_authenticated!, unless: -> { Rails.env.development? }

  def show
    # take either user_id with a start date & end date
    start_date = Date.parse(params[:start_date]) if params[:start_date].present?
    start_date ||= 10.years.ago
    end_date = Date.parse(params[:end_date]) if params[:end_date].present?
    end_date ||= Date.today

    query = Heartbeat
    query = query.where(time: start_date..end_date)
    if params[:user_id].present? || params[:user_email].present?
      user_id = params[:user_id] || find_by_email(params[:user_email])

      return render plain: "User not found", status: :not_found unless user_id.present?

      query = query.where(user_id: params[:user_id]) if params[:user_id].present?
    end

    render plain: query.duration_seconds
  end

  private

  def ensure_authenticated!
    token = request.headers["Authorization"]&.split(" ")&.last
    token ||= params[:api_key]

    render plain: "Unauthorized", status: :unauthorized unless token == ENV["STATS_API_KEY"]
  end

  def find_by_email(email)
    cache_key = "user_id_by_email/#{email}"
    slack_id = Rails.cache.fetch(cache_key, expires_in: 1.week) do
      response = HTTP
        .auth("Bearer #{ENV["SLACK_USER_OAUTH_TOKEN"]}")
        .get("https://slack.com/api/users.lookupByEmail", params: { email: email })

      JSON.parse(response.body)["user"]["id"]
    rescue => e
      Rails.logger.error("Error finding user by email: #{e}")
      nil
    end

    Rails.cache.delete(cache_key) if slack_id.nil?

    slack_id
  end
end
