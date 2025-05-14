class ScanRepoEventsForCommitsJob < ApplicationJob
  queue_as :literally_whenever

  include GoodJob::ActiveJobExtensions::Concurrency
  good_job_control_concurrency_with(
    total_limit: 1, # Only one instance of this job should run at a time
    key: -> { self.class.name },
    drop: true # If another instance is running or queued, drop this one
  )

  def perform
    Rails.logger.info "[ScanRepoEventsForCommitsJob] Starting scan of RepoHostEvents for new commits."

    # Determine the lookback window. Consider events from the last N days.
    # If you have a way to track processed events (e.g., a new column on RepoHostEvent),
    # you could use that. For now, we'll use a time window and rely on Commit.exists?
    # to avoid re-processing.
    time_window_start = 90.days.ago

    # Process events in batches to manage memory
    # Filter for GitHub PushEvents initially
    RepoHostEvent
      .where(provider: RepoHostEvent.providers[:github])
      .where("raw_event_payload->>'type' = ?", 'PushEvent') # Efficiently query JSONB
      .where("created_at >= ?", time_window_start) # Focus on recent events
      .order(created_at: :desc) # Process newer events first, potentially stopping earlier
      .find_each(batch_size: 100) do |event|
      
      process_event(event)
    end

    Rails.logger.info "[ScanRepoEventsForCommitsJob] Finished scan."
  end

  private

  def process_event(event)
    user = event.user
    unless user
      Rails.logger.warn "[ScanRepoEventsForCommitsJob] Event ID #{event.id} has no associated user. Skipping."
      return
    end

    payload = event.raw_event_payload
    # Safely access nested commit data from the JSON payload
    commits_data = payload.dig('payload', 'commits')

    unless commits_data.is_a?(Array) && commits_data.any?
      # Rails.logger.debug "[ScanRepoEventsForCommitsJob] Event ID #{event.id} (User ##{user.id}) is a PushEvent but has no commits. Skipping."
      return
    end

    commits_data.each do |commit_info|
      commit_sha = commit_info['sha']
      # The 'url' in the PushEvent's commit object is the API URL for that commit
      commit_api_url = commit_info['url'] 

      if commit_sha.blank? || commit_api_url.blank?
        Rails.logger.warn "[ScanRepoEventsForCommitsJob] Event ID #{event.id} (User ##{user.id}) has a commit with missing SHA or API URL. Info: #{commit_info.inspect}"
        next
      end
      
      # Main check: Only enqueue if the commit SHA is not already in the Commit table.
      # This is crucial for idempotency and efficiency.
      unless Commit.exists?(sha: commit_sha)
        Rails.logger.info "[ScanRepoEventsForCommitsJob] Enqueuing ProcessCommitJob for SHA #{commit_sha}, User ##{user.id}, Provider #{event.provider}."
        ProcessCommitJob.perform_later(user.id, commit_sha, commit_api_url, event.provider.to_s)
      end
    end
  rescue JSON::ParserError => e
    Rails.logger.error "[ScanRepoEventsForCommitsJob] Failed to parse raw_event_payload for Event ID #{event.id}: #{e.message}"
  rescue => e # Catch other potential errors during event processing
    Rails.logger.error "[ScanRepoEventsForCommitsJob] Error processing Event ID #{event.id}: #{e.message}\n#{e.backtrace.take(5).join("\n")}"
  end
end
