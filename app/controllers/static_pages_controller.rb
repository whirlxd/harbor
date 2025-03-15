class StaticPagesController < ApplicationController
  def index
    # Get today's leaderboard for both authenticated and unauthenticated users
    @leaderboard = Leaderboard.find_by(start_date: Date.current, deleted_at: nil)

    if current_user
      unless params[:date].blank?
        # implement this later– for now just redirect to a random video
        allowed_hosts = FlavorText.random_time_video.map { |v| URI.parse(v).host }
        redirect_to FlavorText.random_time_video.sample, allow_other_host: allowed_hosts
      end

      @show_wakatime_setup_notice = current_user.heartbeats.empty?
      @setup_social_proof = get_setup_social_proof if @show_wakatime_setup_notice

      @project_names = current_user.project_names
      @projects = current_user.project_labels
      @current_project = current_user.active_project

      # Get languages and editors in a single query using window functions
      results = current_user.heartbeats.today
        .select(
          :language,
          :editor,
          "COUNT(*) OVER (PARTITION BY language) as language_count",
          "COUNT(*) OVER (PARTITION BY editor) as editor_count"
        )
        .distinct
        .to_a

      # Process results to get sorted languages and editors
      language_counts = results
        .map { |r| [ r.language, r.language_count ] }
        .reject { |lang, _| lang.nil? || lang.empty? }
        .uniq
        .sort_by { |_, count| -count }

      editor_counts = results
        .map { |r| [ r.editor, r.editor_count ] }
        .reject { |ed, _| ed.nil? || ed.empty? }
        .uniq
        .sort_by { |_, count| -count }

      @todays_languages = language_counts.map(&:first)
      @todays_editors = editor_counts.map(&:first)
      @show_logged_time_sentence = @todays_languages.any? || @todays_editors.any?
    else
      begin
        in_past_week = Heartbeat.where("time > ?", 1.week.ago.to_f).distinct.count(:user_id)
        in_past_day = Heartbeat.where("time > ?", 1.day.ago.to_f).distinct.count(:user_id)
        in_past_hour = Heartbeat.where("time > ?", 1.hour.ago.to_f).distinct.count(:user_id)
        @social_proof ||= begin
          if in_past_hour > 5
            "In the past hour, #{in_past_hour} Hack Clubbers have coded with Hackatime."
          elsif in_past_day > 5
            "In the past day, #{in_past_day} Hack Clubbers have coded with Hackatime."
          elsif in_past_week > 5
            "In the past week, #{in_past_week} Hack Clubbers have coded with Hackatime."
          end
        end

        @users_tracked = Heartbeat.distinct.count(:user_id)
        @hours_tracked = Heartbeat.duration_seconds / 3600
      rescue ActiveRecord::StatementInvalid => e
        # Handle timestamp overflow errors
        Rails.logger.error "Error calculating statistics: #{e.message}"
        @users_tracked = Heartbeat.distinct.count(:user_id) rescue 0
        @hours_tracked = 0
      end
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

  private

  def get_setup_social_proof
    begin
      # Count users who set up in different time periods
      in_past_5_min = Heartbeat.where("time > ? AND source_type = ?", 5.minutes.ago.to_f, Heartbeat.source_types[:test_entry])
                              .distinct.count(:user_id)
      in_past_hour = Heartbeat.where("time > ? AND source_type = ?", 1.hour.ago.to_f, Heartbeat.source_types[:test_entry])
                             .distinct.count(:user_id)
      in_past_day = Heartbeat.where("time > ? AND source_type = ?", 1.day.ago.to_f, Heartbeat.source_types[:test_entry])
                            .distinct.count(:user_id)
      in_past_week = Heartbeat.where("time > ? AND source_type = ?", 1.week.ago.to_f, Heartbeat.source_types[:test_entry])
                             .distinct.count(:user_id)
      in_past_month = Heartbeat.where("time > ? AND source_type = ?", 1.month.ago.to_f, Heartbeat.source_types[:test_entry])
                              .distinct.count(:user_id)
      this_year = Heartbeat.where("time > ? AND source_type = ?", Time.current.beginning_of_year.to_f, Heartbeat.source_types[:test_entry])
                          .distinct.count(:user_id)

      # Choose the most appropriate time period based on user count
      if in_past_5_min >= 1
        "#{in_past_5_min} Hack Clubber#{in_past_5_min > 1 ? 's' : ''} set up Hackatime in the past 5 minutes"
      elsif in_past_hour >= 3
        "#{in_past_hour} Hack Clubbers set up Hackatime in the past hour"
      elsif in_past_day >= 5
        "#{in_past_day} Hack Clubbers set up Hackatime in the past day"
      elsif in_past_week >= 5
        "#{in_past_week} Hack Clubbers set up Hackatime in the past week"
      elsif in_past_month >= 5
        "#{in_past_month} Hack Clubbers set up Hackatime in the past month"
      else
        "#{this_year} Hack Clubbers set up Hackatime this year"
      end
    rescue ActiveRecord::StatementInvalid => e
      # Handle timestamp overflow errors
      Rails.logger.error "Error calculating setup social proof: #{e.message}"
      "Join the community of Hack Clubbers using Hackatime"
    end
  end
end
