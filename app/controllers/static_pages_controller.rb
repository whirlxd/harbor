class StaticPagesController < ApplicationController
  def index
    if current_user
      # get all unique project names
      @project_names = current_user.project_names
      @projects = current_user.projects
      @current_project = current_user.active_project
      @project_durations = @project_names.map do |project|
        {
          project: @projects.find { |p| p.project_key == project }&.label || project || "Unknown",
          duration: current_user.heartbeats.where(project: project).duration_formatted
        }
      end
      @current_project_duration = @project_durations.find { |p| p[:project] == @current_project }&.[](:duration)
    end
  end
end
