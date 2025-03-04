class Api::Hackatime::V1::HackatimeController < ApplicationController
  before_action :set_user, except: [ :index ]
  skip_before_action :verify_authenticity_token

  def index
    redirect_to root_path
  end

  def push_heartbeats
    puts "Raw params: #{params.inspect}"
    puts "Creating heartbeat with params: #{heartbeat_params}"
    attrs = heartbeat_params.merge({ user: @user })
    puts "Merged attrs: #{attrs}"
    new_heartbeat = Heartbeat.new(attrs)

    if new_heartbeat.save!
      render json: { responses: [ { heartbeat: new_heartbeat.attributes, status: 201 } ] }, status: :created
    else
      render json: { error: "Failed to create heartbeat: #{new_heartbeat.errors.full_messages}" }, status: :unprocessable_entity
    end
  end

  def push_heartbeats_bulk
    new_heartbeats = []

    ActiveRecord::Base.transaction do
      new_heartbeats = heartbeat_bulk_params.map do |heartbeat|
        attrs = heartbeat.merge({ user_id: @user.id })
        Heartbeat.create(attrs)
      end
    end

    responses = []
    new_heartbeats.each do |heartbeat|
      responses << [ heartbeat.attributes, heartbeat.persisted? ? 201 : 422 ]
    end

    render json: { responses: responses }, status: :success
  end

  def status_bar_today
    hbt = @user.heartbeats.today

    render json: {
      "data": {
        "grand_total": {
          "decimal": "yolo",
          "digital": "wahoo",
          "hours": hbt.duration_seconds / 3600,
          "minutes": (hbt.duration_seconds % 3600) / 60,
          "text": @user.format_extension_text(hbt.duration_seconds),
          "total_seconds": hbt.duration_seconds
        },
        "categories": hbt.distinct.pluck(:category),
        "dependencies": hbt.distinct.pluck(:dependencies),
        "editors": hbt.distinct.pluck(:editor),
        "languages": hbt.distinct.pluck(:language),
        "machines": hbt.distinct.pluck(:machine),
        "operating_systems": hbt.distinct.pluck(:operating_system),
        "projects": hbt.distinct.pluck(:project),
        "range": {
          "text": "Today",
          "timezone": "UTC"
        }
      }
    }
  end

  private

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
