class UpdateAirtableUserDataJob < ApplicationJob
  queue_as :latency_5m

  Table = Norairrecord.table(ENV["LOOPS_AIRTABLE_PAT"], "app6VcLJoYFbDdGWK", "tblnzmotZ55MFBfV4")

  def perform
    users_with_heartbeats.includes(:email_addresses).find_in_batches(batch_size: 100) do |batch|
      records = []
      batch.each do |user|
        first_heartbeat_time = user.heartbeats.with_valid_timestamps.order(time: :asc).limit(1).pluck(:time).first
        first_direct_heartbeat_time = user.heartbeats.direct_entry.with_valid_timestamps.order(time: :asc).limit(1).pluck(:time).first
        first_test_heartbeat_time = user.heartbeats.test_entry.with_valid_timestamps.order(time: :asc).limit(1).pluck(:time).first
        next if first_heartbeat_time > Time.now.to_i
        user.email_addresses.map do |email_address|
          records << Table.new({
            email: email_address.email,
            first_direct_heartbeat_time: first_direct_heartbeat_time ? Time.at(first_direct_heartbeat_time.to_i).iso8601 : nil,
            first_test_heartbeat_time: first_test_heartbeat_time ? Time.at(first_test_heartbeat_time.to_i).iso8601 : nil,
            first_heartbeat_time: Time.at(first_heartbeat_time.to_i).iso8601 # airtable expects milliseconds
          })
        end
      end
      Table.batch_upsert(records, "email")
    end
  end

  private

  def users_with_heartbeats
    User.where(id: Heartbeat.with_valid_timestamps.group(:user_id).pluck(:user_id))
  end
end
