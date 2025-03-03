class HackatimeController < ApplicationController
  before_action :set_user

  def push_heartbeats
    @user.heartbeats.create(heartbeat_params)
  end

  def push_heartbeats_bulk
    @user.heartbeats.create(heartbeat_params)
  end

  private

  def set_user
    # each user has a Hackatime::User with an api_key
    # the api_key is sent in the Authorization header as a Bearer token
    api_key = request.headers["Authorization"].split(" ")[1]
    @user = Hackatime::User.find_by(api_key: api_key)
    render json: { error: "Unauthorized" }, status: :unauthorized unless @user
  end

  def heartbeat_params
    params.require(:heartbeat).permit(
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
    )
  end
end
