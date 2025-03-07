class Api::Hackatime::V1::HackatimeController < ApplicationController
  before_action :set_user, except: [ :index ]
  skip_before_action :verify_authenticity_token

  def index
    redirect_to root_path
  end

  def push_heartbeats
    # example response:
    # status: 202
    # {
    #   ...heartbeat_data
    # }

    heartbeat_array = [ heartbeat_params ]
    new_heartbeat = handle_heartbeat(heartbeat_array)&.first&.first
    render json: new_heartbeat, status: :accepted
  end

  def push_heartbeats_bulk
    # example response:
    # status: 201
    # {
    #   "responses": [
    #     [{...heartbeat_data}, 201],
    #     [{...heartbeat_data}, 201],
    #     [{...heartbeat_data}, 201]
    #   ]
    # }

    heartbeat_array = heartbeat_bulk_params[:heartbeats].map(&:to_h)
    render json: { responses: handle_heartbeat(heartbeat_array) }, status: :created
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
    heartbeat_array.each do |heartbeat|
      attrs = heartbeat.merge({ user_id: @user.id, source_type: :direct_entry })
      new_heartbeat = Heartbeat.create!(attrs)
      results << [ new_heartbeat, 201 ]
    rescue ActiveRecord::RecordNotUnique
      results << [ new_heartbeat.attributes, 201 ]
    rescue => e
      Rails.logger.error("Error creating heartbeat: #{e.message}")
      results << [ new_heartbeat.attributes, 422 ]
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
    if params[:_json].present?
      { heartbeats: params.permit(_json: [ *heartbeat_keys ])[:_json] }
    else
      params.require(:hackatime).permit(
        heartbeats: [
          *heartbeat_keys
        ]
      )
    end
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
