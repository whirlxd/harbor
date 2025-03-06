class Api::Hackatime::V1::HackatimeController < ApplicationController
  before_action :set_user, except: [ :index ]
  skip_before_action :verify_authenticity_token

  def index
    redirect_to root_path
  end

  def push_heartbeats
    render json: { responses: handle_heartbeat([ heartbeat_params ]) }
  end

  def push_heartbeats_bulk
    render json: { responses: handle_heartbeat(heartbeat_bulk_params[:heartbeats]) }
  end

  def status_bar_today
    hbt = @user.heartbeats.today

    result = {
      data: {
        grand_total: {
          text: @user.format_extension_text(hbt.duration_seconds),
          total_seconds: hbt.duration_seconds
        }
      }
    }

    render json: result
  end

  private

  def handle_heartbeat(heartbeat_array)
    results = []
    heartbeat_array.map(&:to_h).each do |heartbeat|
      attrs = heartbeat.merge({ user_id: @user.id, source_type: :direct_entry })
      new_heartbeat = Heartbeat.create!(attrs)
      results << { heartbeat: new_heartbeat, status: 201 }
    rescue PG::UniqueViolation
      results << { heartbeat: new_heartbeat.attributes, status: 201 }
    rescue => e
      Rails.logger.error("Error creating heartbeat: #{e.message}")
      results << { heartbeat: new_heartbeat.attributes, status: 422 }
    end
    results
  end

  def set_user
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

    @user = valid_key.user
    render json: { error: "Unauthorized" }, status: :unauthorized unless @user
  end

  def heartbeat_keys
    [
      :branch,
      :category,
      :created_at,
      :cursorpos,
      :dependencies,
      :editor,
      :entity,
      :is_write,
      :language,
      :line_additions,
      :line_deletions,
      :lineno,
      :lines,
      :machine,
      :operating_system,
      :project,
      :project_root_count,
      :time,
      :type,
      :user_agent
    ]
  end

  # allow either heartbeat or heartbeats
  def heartbeat_bulk_params
    params.require(:hackatime).permit(
      heartbeats: [
        *heartbeat_keys
      ]
    )
  end

  def heartbeat_params
    # Handle both direct params and _json format from WakaTime
    if params[:_json].present?
      params[:_json].first.permit(*heartbeat_keys)
    elsif params[:hackatime].present?
      params.require(:hackatime).permit(*heartbeat_keys)
    else
      params.permit(*heartbeat_keys)
    end
  end
end
