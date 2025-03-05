class OneTime::GenerateUniqueHeartbeatHashesJob < ApplicationJob
  queue_as :default

  def perform
    ActiveRecord::Base.transaction do
      Heartbeat.where(fields_hash: nil).find_each(batch_size: 5000) do |heartbeat|
        heartbeat.send(:set_fields_hash!)
        heartbeat.save!
      end
    end

    # Delete duplicates in a single query, keeping the oldest record for each fields_hash
    deleted_count = Heartbeat.where.not(
      id: Heartbeat.select("DISTINCT ON (fields_hash) id")
                   .order("fields_hash, created_at")
    ).delete_all

    puts "Deleted #{deleted_count} duplicate heartbeat(s)"
  end
end
