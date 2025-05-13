class StaticPagesController < ApplicationController
  before_action :ensure_current_user, only: %i[
    filterable_dashboard
    filterable_dashboard_content
  ]

  def index
    @leaderboard = Leaderboard.where.associated(:entries)
                              .where(start_date: Date.current)
                              .where(deleted_at: nil)
                              .where(period_type: :daily)
                              .distinct
                              .first

    # Get active projects for the mini leaderboard
    @active_projects = Cache::ActiveProjectsJob.perform_now

    if current_user
      flavor_texts = FlavorText.motto + FlavorText.conditional_mottos(current_user)
      flavor_texts += FlavorText.rare_motto if Random.rand(10) < 1
      @flavor_text = flavor_texts.sample

      unless params[:date].blank?
        # implement this later– for now just redirect to a random video
        allowed_hosts = FlavorText.random_time_video.map { |v| URI.parse(v).host }
        redirect_to FlavorText.random_time_video.sample, allow_other_host: allowed_hosts
      end

      if current_user.heartbeats.empty? || params[:show_wakatime_setup_notice]
        @show_wakatime_setup_notice = true

        setup_social_proof = Cache::SetupSocialProofJob.perform_now
        @ssp_message = setup_social_proof[:message]
        @ssp_users_recent = setup_social_proof[:users_recent]
        @ssp_users_size = setup_social_proof[:users_size]
      end

      # Get languages and editors in a single query using window functions
      Time.use_zone(current_user.timezone) do
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
        @todays_duration = current_user.heartbeats.today.duration_seconds

        if @todays_duration > 1.minute
          @show_logged_time_sentence = @todays_languages.any? || @todays_editors.any?
        end
      end

      cached_data = filterable_dashboard_data
      cached_data.entries.each do |key, value|
        instance_variable_set("@#{key}", value)
      end
    else
      @usage_social_proof = Cache::UsageSocialProofJob.perform_now

      @home_stats = Cache::HomeStatsJob.perform_now
    end
  end

  def project_durations
    return unless current_user

    @project_repo_mappings = current_user.project_repo_mappings
    cache_key = "user_#{current_user.id}_project_durations_#{params[:interval]}"
    cache_key += "_#{params[:from]}_#{params[:to]}" if params[:interval] == "custom"

    project_durations = Rails.cache.fetch(cache_key, expires_in: 1.minute) do
      heartbeats = current_user.heartbeats.filter_by_time_range(params[:interval], params[:from], params[:to])
      project_times = heartbeats.group(:project).duration_seconds
      project_labels = current_user.project_labels
      project_times.map do |project, duration|
        {
          project: project_labels.find { |p| p.project_key == project }&.label || project || "Unknown",
          repo_url: @project_repo_mappings.find { |p| p.project_name == project }&.repo_url,
          duration: duration
        }
      end.filter { |p| p[:duration].positive? }.sort_by { |p| p[:duration] }.reverse
    end
    render partial: "project_durations", locals: { project_durations: project_durations }
  end

  def activity_graph
    return unless current_user

    user_tz = current_user.timezone
    cache_key = "user_#{current_user.id}_daily_durations_#{user_tz}"

    daily_durations = Rails.cache.fetch(cache_key, expires_in: 1.minute) do
      Time.use_zone(user_tz) do
        current_user.heartbeats.daily_durations(user_timezone: user_tz).to_h
      end
    end

    # Consider 8 hours as a "full" day of coding
    length_of_busiest_day = 8.hours.to_i  # 28800 seconds

    render partial: "activity_graph", locals: {
      daily_durations: daily_durations,
      length_of_busiest_day: length_of_busiest_day
    }
  end

  def currently_hacking
    locals = Cache::CurrentlyHackingJob.perform_now

    render partial: "currently_hacking", locals: locals
  end

  def streak
    render partial: "streak"
  end

  def filterable_dashboard
    cached_data = filterable_dashboard_data
    cached_data.entries.each do |key, value|
      instance_variable_set("@#{key}", value)
    end

    render partial: "filterable_dashboard"
  end

  def filterable_dashboard_content
    cached_data = filterable_dashboard_data
    cached_data.entries.each do |key, value|
      instance_variable_set("@#{key}", value)
    end

    render partial: "filterable_dashboard_content"
  end

  def 🃏
    redirect_to root_path unless current_user && current_user.slack_uid.present?

    record = HTTP.auth("Bearer #{ENV.fetch("WILDCARD_AIRTABLE_KEY")}").patch("https://api.airtable.com/v0/appt3yVn2nbiUaijm/tblRCAMjfQ4MIsMPp",
      json: {
        records: [
          {
            fields: {
              slack_id: current_user.slack_uid
            }
          }
        ],
        performUpsert: {
          fieldsToMergeOn: [ "slack_id" ]
        }
      }
    )
    record_data = JSON.parse(record.body)

    record_id = record_data.dig("records", 0, "id")

    redirect_to root_path unless record_id&.present?

    # if record is created, set a new auth_key:
    auth_key = SecureRandom.hex(16)
    HTTP.auth("Bearer #{ENV.fetch("WILDCARD_AIRTABLE_KEY")}").patch("https://api.airtable.com/v0/appt3yVn2nbiUaijm/tblRCAMjfQ4MIsMPp",
      json: {
        records: [
          { id: record_id, fields: { auth_key: auth_key } }
        ]
      }
    )

    wildcard_host = ENV.fetch("WILDCARD_HOST")

    redirect_to "#{wildcard_host}?auth_key=#{auth_key}", allow_other_host: wildcard_host
  end

  def timeline
    # for span calculations (visual blocks in the timeline)
    timeout_duration = 10.minutes.to_i # This remains for span display

    # Determine the date to display (default to today)
    @date = params[:date] ? Date.parse(params[:date]) : Time.current.to_date

    # Calculate next and previous dates
    @next_date = @date + 1.day
    @prev_date = @date - 1.day

    # Step 1: Consolidate User Loading
    user_ids_to_fetch = [
      current_user&.id, # Handle potential nil current_user
      1,
      10,
      1792,
      69,
      1476,
      805,
      2003,
      2011
    ].compact.uniq # Remove nils and duplicates

    # Fetch all users in one query and create a hash for easy lookup
    users_by_id = User.where(id: user_ids_to_fetch).index_by(&:id)

    # Step 1.1: Fetch ProjectRepoMappings for all relevant users
    # Store them in a hash for quick lookup: { user_id => { project_name => mapping_object } }
    mappings_by_user_project = ProjectRepoMapping.where(user_id: users_by_id.keys)
                                                 .group_by(&:user_id)
                                                 .transform_values { |mappings| mappings.index_by(&:project_name) }

    # Get the user objects in the desired order based on the original array
    # Filter out users not found in the database
    users_to_process = user_ids_to_fetch.map { |id| users_by_id[id] }.compact

    # Step 2: Fetch All Relevant Heartbeats in One Go
    # Use the determined @date
    # Convert to application's beginning/end of day for consistent timestamp comparison
    # Assuming application timezone is UTC for these boundary calculations,
    # or use Time.zone.local_to_utc(@date.beginning_of_day).to_f etc. if app timezone is different
    # For simplicity and consistency with existing code, using @date directly converted to Time then to_f
    start_of_day_timestamp = @date.beginning_of_day.to_f
    end_of_day_timestamp = @date.end_of_day.to_f

    all_heartbeats = Heartbeat
                      .where(user_id: user_ids_to_fetch, deleted_at: nil)
                      .where('time >= ? AND time <= ?', start_of_day_timestamp, end_of_day_timestamp)
                      .select(:id, :user_id, :time, :entity, :project, :editor, :language)
                      .order(:user_id, :time)
                      .to_a

    # Group heartbeats by user ID for easier processing
    heartbeats_by_user_id = all_heartbeats.group_by(&:user_id)

    # Step 3: Process Heartbeats in Ruby
    @users_with_timeline_data = []

    users_to_process.each do |user|
      # Calculate total coded time for the day using 2-minute timeout
      # This query will use Heartbeat.duration_seconds which defaults to a 2-min timeout
      user_daily_heartbeats_relation = Heartbeat.where(user_id: user.id, deleted_at: nil)
                                                .where('time >= ? AND time <= ?', start_of_day_timestamp, end_of_day_timestamp)
      total_coded_time_seconds = user_daily_heartbeats_relation.duration_seconds

      # Process spans for visual display (uses 10-minute timeout)
      user_heartbeats_for_spans = heartbeats_by_user_id[user.id] || []
      calculated_spans_with_details = []

      if user_heartbeats_for_spans.any?
        current_span_heartbeats = []
        user_heartbeats_for_spans.each_with_index do |heartbeat, index|
          current_span_heartbeats << heartbeat
          is_last_heartbeat = (index == user_heartbeats_for_spans.length - 1)
          time_to_next = is_last_heartbeat ? Float::INFINITY : (user_heartbeats_for_spans[index + 1].time - heartbeat.time)

          if time_to_next > timeout_duration || is_last_heartbeat # timeout_duration is 10 minutes here
            if current_span_heartbeats.any?
              start_time_numeric = current_span_heartbeats.first.time
              last_hb_time_numeric = current_span_heartbeats.last.time
              span_duration = last_hb_time_numeric - start_time_numeric
              span_duration = 0 if span_duration < 0

              # Aggregate details from the heartbeats collected for THIS span
              files = current_span_heartbeats.map { |h| h.entity&.split('/')&.last }.compact.uniq
              projects_edited_details_for_span = []
              # Get unique, non-blank project names from the heartbeats in the current span
              unique_project_names_in_current_span = current_span_heartbeats.map(&:project).compact.reject(&:blank?).uniq
              
              unique_project_names_in_current_span.each do |p_name|
                repo_mapping = mappings_by_user_project[user.id]&.dig(p_name)
                projects_edited_details_for_span << {
                  name: p_name,
                  repo_url: repo_mapping&.repo_url
                }
              end

              editors = current_span_heartbeats.map(&:editor).compact.uniq
              languages = current_span_heartbeats.map(&:language).compact.uniq

              # Store the span using numeric start_time and duration, as the view likely expects Time objects or handles numeric ones.
              # Pass numeric times for consistency with how heartbeats are often stored/compared.
              calculated_spans_with_details << {
                start_time: start_time_numeric,
                # end_time: last_hb_time_numeric, # Pass numeric end timestamp if needed
                duration: span_duration, # Pass calculated duration
                files_edited: files,
                projects_edited_details: projects_edited_details_for_span, # NEW field
                editors: editors,
                languages: languages
              }
              current_span_heartbeats = []
            end
          end
        end
      end

      # Add the user and their calculated spans to the final result
      if calculated_spans_with_details.any? || total_coded_time_seconds > 0 # Ensure user is added if they have coded time, even with no visual spans
        @users_with_timeline_data << {
          user: user,
          spans: calculated_spans_with_details,
          total_coded_time: total_coded_time_seconds # Add this new piece of data
        }
      end

    end # end loop through users_to_process

    # Render the partial, passing the processed data and the date
    render partial: "timeline", locals: {
      users_with_timeline_data: @users_with_timeline_data,
      primary_user: users_to_process.first || current_user,
      date: @date,
      # Pass next_date and prev_date to the partial
      next_date: @next_date,
      prev_date: @prev_date
    }
  end

  private

  def ensure_current_user
    redirect_to root_path, alert: "You must be logged in to view this page" unless current_user
  end

  def filterable_dashboard_data
    filters = %i[project language operating_system editor category]

    # Cache key based on user and filter parameters
    cache_key = []
    cache_key << current_user
    filters.each do |filter|
      cache_key << params[filter]
    end

    filtered_heartbeats = current_user.heartbeats
    # Load filter options and apply filters with caching
    Rails.cache.fetch(cache_key, expires_in: 5.minutes) do
      result = {}
      # Load filter options
      Time.use_zone(current_user.timezone) do
        filters.each do |filter|
          group_by_time = current_user.heartbeats.group(filter).duration_seconds
          result[filter] = group_by_time.sort_by { |k, v| v }
                                        .reverse.map(&:first)
                                        .compact_blank

          if params[filter].present?
            filter_arr = params[filter].split(",")
            filtered_heartbeats = filtered_heartbeats.where(filter => filter_arr)

            result["singular_#{filter}"] = filter_arr.length == 1
          end
        end

        # Only use the concern for time filtering
        filtered_heartbeats = filtered_heartbeats.filter_by_time_range(params[:interval], params[:from], params[:to])

        result[:filtered_heartbeats] = filtered_heartbeats

        # Calculate stats for filtered data
        result[:total_time] = filtered_heartbeats.duration_seconds
        result[:total_heartbeats] = filtered_heartbeats.count

        filters.each do |filter|
          result["top_#{filter}"] = filtered_heartbeats.group(filter)
                                                       .duration_seconds
                                                       .max_by { |_, v| v }
                                                       &.first
        end

        # Prepare project durations data
        result[:project_durations] = filtered_heartbeats
          .group(:project)
          .duration_seconds
          .sort_by { |_, duration| -duration }
          .first(10)
          .to_h unless result["singular_project"]

        # Prepare pie chart data
        %i[language editor operating_system category].each do |filter|
          result["#{filter}_stats"] = filtered_heartbeats
            .group(filter)
            .duration_seconds
            .sort_by { |_, duration| -duration }
            .first(10)
            .map { |k, v| [ k.presence || "Unknown", v ] }
            .to_h unless result["singular_#{filter}"]
        end
        # result[:language_stats] = filtered_heartbeats
        #   .group(:language)
        #   .duration_seconds
        #   .sort_by { |_, duration| -duration }
        #   .first(10)
        #   .map { |k, v| [ k.presence || "Unknown", v ] }
        #   .to_h unless result["singular_language"]

        # result[:editor_stats] = filtered_heartbeats
        #   .group(:editor)
        #   .duration_seconds
        #   .sort_by { |_, duration| -duration }
        #   .map { |k, v| [ k.presence || "Unknown", v ] }
        #   .to_h unless result["singular_editor"]

        # result[:operating_system_stats] = filtered_heartbeats
        #   .group(:operating_system)
        #   .duration_seconds
        #   .sort_by { |_, duration| -duration }
        #   .map { |k, v| [ k.presence || "Unknown", v ] }
        #   .to_h unless result["singular_operating_system"]

        # result[:category_stats] = filtered_heartbeats
        #   .group(:category)
        #   .duration_seconds
        #   .sort_by { |_, duration| -duration }
        #   .map { |k, v| [ k.presence || "Unknown", v ] }
        #   .to_h unless result["singular_category"]

        # Calculate weekly project stats for the last 6 months
        result[:weekly_project_stats] = {}
        (0..25).each do |week_offset|  # 26 weeks = 6 months
          week_start = week_offset.weeks.ago.beginning_of_week
          week_end = week_offset.weeks.ago.end_of_week

          week_stats = filtered_heartbeats
            .where(time: week_start.to_f..week_end.to_f)
            .group(:project)
            .duration_seconds

          result[:weekly_project_stats][week_start.to_date.iso8601] = week_stats
        end
      end

      result
    end
  end
end
