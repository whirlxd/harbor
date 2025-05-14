class Admin::TimelineController < Admin::BaseController
  include ApplicationHelper # For short_time_simple, short_time_detailed helpers

  def show
    # for span calculations (visual blocks in the timeline)
    timeout_duration = 10.minutes.to_i # This remains for span display

    # Determine the date to display (default to today)
    @date = params[:date] ? Date.parse(params[:date]) : Time.current.to_date

    # Calculate next and previous dates
    @next_date = @date + 1.day
    @prev_date = @date - 1.day

    # Step 1: Consolidate User Loading
    # Note: current_user in an admin controller is the admin user.
    # The original list of user_ids_to_fetch includes some hardcoded IDs.
    # This logic is preserved but might need review for an admin-specific timeline.
    user_ids_to_fetch = [
      current_user&.id, # Admin's own data (if they are also a tracked user)
      1, # Example: User.find(1) if it's relevant
      10, 1792, 69, 1476, 805, 2003, 2011 # Original hardcoded IDs
    ].compact.uniq

    users_by_id = User.where(id: user_ids_to_fetch).index_by(&:id)

    mappings_by_user_project = ProjectRepoMapping.where(user_id: users_by_id.keys)
                                                 .group_by(&:user_id)
                                                 .transform_values { |mappings| mappings.index_by(&:project_name) }

    users_to_process = user_ids_to_fetch.map { |id| users_by_id[id] }.compact

    start_of_day_timestamp = @date.beginning_of_day.to_f
    end_of_day_timestamp = @date.end_of_day.to_f

    all_heartbeats = Heartbeat
                      .where(user_id: user_ids_to_fetch, deleted_at: nil)
                      .where('time >= ? AND time <= ?', start_of_day_timestamp, end_of_day_timestamp)
                      .select(:id, :user_id, :time, :entity, :project, :editor, :language)
                      .order(:user_id, :time)
                      .to_a

    heartbeats_by_user_id = all_heartbeats.group_by(&:user_id)

    @users_with_timeline_data = []

    users_to_process.each do |user|
      user_daily_heartbeats_relation = Heartbeat.where(user_id: user.id, deleted_at: nil)
                                                .where('time >= ? AND time <= ?', start_of_day_timestamp, end_of_day_timestamp)
      total_coded_time_seconds = user_daily_heartbeats_relation.duration_seconds

      user_heartbeats_for_spans = heartbeats_by_user_id[user.id] || []
      calculated_spans_with_details = []

      if user_heartbeats_for_spans.any?
        current_span_heartbeats = []
        user_heartbeats_for_spans.each_with_index do |heartbeat, index|
          current_span_heartbeats << heartbeat
          is_last_heartbeat = (index == user_heartbeats_for_spans.length - 1)
          time_to_next = is_last_heartbeat ? Float::INFINITY : (user_heartbeats_for_spans[index + 1].time - heartbeat.time)

          if time_to_next > timeout_duration || is_last_heartbeat
            if current_span_heartbeats.any?
              start_time_numeric = current_span_heartbeats.first.time
              last_hb_time_numeric = current_span_heartbeats.last.time
              span_duration = last_hb_time_numeric - start_time_numeric # This is span length, not necessarily active coding time within span
              span_duration = 0 if span_duration < 0

              files = current_span_heartbeats.map { |h| h.entity&.split('/')&.last }.compact.uniq
              projects_edited_details_for_span = []
              unique_project_names_in_current_span = current_span_heartbeats.map(&:project).compact.reject(&:blank?).uniq

              unique_project_names_in_current_span.each do |p_name|
                repo_mapping = mappings_by_user_project.dig(user.id, p_name)
                projects_edited_details_for_span << {
                  name: p_name,
                  repo_url: repo_mapping&.repo_url
                }
              end

              editors = current_span_heartbeats.map(&:editor).compact.uniq
              languages = current_span_heartbeats.map(&:language).compact.uniq

              calculated_spans_with_details << {
                start_time: start_time_numeric,
                end_time: last_hb_time_numeric, # Explicitly pass end_time of the span
                duration: span_duration, # Duration of the span itself
                files_edited: files,
                projects_edited_details: projects_edited_details_for_span,
                editors: editors,
                languages: languages
              }
              current_span_heartbeats = []
            end
          end
        end
      end

      if calculated_spans_with_details.any? || total_coded_time_seconds > 0
        @users_with_timeline_data << {
          user: user,
          spans: calculated_spans_with_details,
          total_coded_time: total_coded_time_seconds # Actual coded time for the user for the day
        }
      end
    end

    @primary_user = users_to_process.first || current_user # current_user is the admin

    render :show # Renders app/views/admin/timeline/show.html.erb
  end
end 