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
    query = query.where(user_id: params[:user_id]) if params[:user_id].present?

    render plain: query.duration_seconds
  end

  private

  def ensure_authenticated!
    token = request.headers["Authorization"]&.split(" ")&.last
    token ||= params[:api_key]

    return render plain: "Unauthorized", status: :unauthorized unless token == ENV["STATS_API_KEY"]
  end
end