class OneTime::GenerateUniqueHeartbeatHashesJob < ApplicationJob
  queue_as :default

  # only allow one instance of this job to run at a time
  good_job_control_concurrency_with(
    key: -> { "generate_unique_heartbeat_hashes_job" },
    total_limit: 1,
  )

  def perform(scope = Heartbeat.where(fields_hash: nil))
    scope_count = scope.count
    puts "Starting to generate unique heartbeat hashes for #{scope_count} heartbeats"
    index = 0
    scope.in_batches(of: 1000) do |batch|
      # Process records in smaller chunks to avoid statement size limits
      batch.each_slice(250) do |chunk|
        updates = chunk.map do |heartbeat|
          index += 1
          puts "Processing heartbeat #{heartbeat.id} (#{index} of #{batch.size})"
          field_hash = Heartbeat.generate_fields_hash(heartbeat.attributes)
          puts "Field hash: #{field_hash}"
          [ heartbeat.id, field_hash ]
        end

        # Update creates n queries even when passed an array of records to update, so
        # we're using a SQL CASE statement to update the records in a single query.
        # Prior work: https://gist.github.com/zoltan-nz/6390986
        case_statement = updates.map { |id, hash| "WHEN id = #{id} THEN '#{hash}'" }.join(" ")
        Heartbeat.where(id: updates.map(&:first))
                 .update_all("fields_hash = CASE #{case_statement} END")
      end
    end

    # Delete all heartbeats without a user_id
    Heartbeat.where(user_id: nil).delete_all

    distinct_ids = Heartbeat.select("DISTINCT ON (fields_hash) id")
                           .order("fields_hash, created_at")
                           .pluck("id")
    total_heartbeats = Heartbeat.count
    total_distinct_heartbeats = distinct_ids.count

    puts "Found #{total_distinct_heartbeats} distinct heartbeat(s) out of #{total_heartbeats} total"

    deleted_count = Heartbeat.where.not(
      id: distinct_ids
    ).delete_all

    puts "Deleted #{deleted_count} duplicate heartbeat(s)"
  end
end
