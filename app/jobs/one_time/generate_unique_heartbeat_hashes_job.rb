class OneTime::GenerateUniqueHeartbeatHashesJob < ApplicationJob
  queue_as :default

  def perform
    ActiveRecord::Base.transaction do
      Heartbeat.in_batches(of: 5000) do |batch|
        updated_heartbeats = []
        batch.each do |heartbeat|
          next if heartbeat.user_id.blank?

          updated_heartbeats << {
            id: heartbeat.id,
            fields_hash: Heartbeat.generate_fields_hash(heartbeat.attributes),
            **heartbeat.attributes.except("id", "created_at", "updated_at")
          }
        end

        puts updated_heartbeats
        Heartbeat.upsert_all(updated_heartbeats, unique_by: [ :id ])
      end
    end

    # Delete all heartbeats without a user_id
    Heartbeat.where(user_id: nil).delete_all

    # Delete duplicates in a single query, keeping the oldest record for each fields_hash
    deleted_count = Heartbeat.where.not(
      id: Heartbeat.select("DISTINCT ON (fields_hash) id")
                   .order("fields_hash, created_at")
    ).delete_all

    puts "Deleted #{deleted_count} duplicate heartbeat(s)"
  end
end
