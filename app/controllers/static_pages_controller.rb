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

    @project_repo_mappings = current_user.project_repo_mappings

    @project_durations = Rails.cache.fetch("user_#{current_user.id}_project_durations", expires_in: 1.minute) do
      project_times = current_user.heartbeats.group(:project).duration_seconds
      project_labels = current_user.project_labels

      project_times.map do |project, duration|
        {
          project: project_labels.find { |p| p.project_key == project }&.label || project || "Unknown",
          repo_url: @project_repo_mappings.find { |p| p.project_name == project }&.repo_url,
          duration: duration
        }
      end.filter { |p| p[:duration].positive? }.sort_by { |p| p[:duration] }.reverse
    end

    render partial: "project_durations", locals: { project_durations: @project_durations }
  end

  def activity_graph
    return unless current_user

    @daily_durations = Rails.cache.fetch("user_#{current_user.id}_daily_durations", expires_in: 1.minute) do
      current_user.heartbeats.daily_durations.to_h
    end

    # Consider 8 hours as a "full" day of coding
    @length_of_busiest_day = 8.hours.to_i  # 28800 seconds

    render partial: "activity_graph", locals: {
      daily_durations: @daily_durations,
      length_of_busiest_day: @length_of_busiest_day
    }
  end
end
