class StaticPagesController < ApplicationController
  def index
    if current_user
      @project_names = current_user.project_names
      @projects = current_user.project_labels
      @current_project = current_user.active_project
    end
  end

  def project_durations
    return unless current_user

    @project_durations = Rails.cache.fetch("user_#{current_user.id}_project_durations", expires_in: 1.minute) do
      project_times = current_user.heartbeats.group(:project).duration_seconds
      project_names = current_user.project_names
      projects = current_user.project_labels

      project_names.map do |project|
        {
          project: projects.find { |p| p.project_key == project }&.label || project || "Unknown",
          duration: project_times[project]
        }
      end.filter { |p| p[:duration].positive? }.sort_by { |p| p[:duration] }.reverse
    end

    render partial: "project_durations", locals: { project_durations: @project_durations }
  end
end
