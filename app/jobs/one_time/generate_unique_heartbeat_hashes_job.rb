class OneTime::GenerateUniqueHeartbeatHashesJob < ApplicationJob
  queue_as :default

  def perform
    ActiveRecord::Base.transaction do
      # batch update the fields_hash
      Heartbeat.where(fields_hash: nil).find_in_batches(of: 5000) do |batch|
        updates = batch.map do |heartbeat|
          [ heartbeat.id, heartbeat.send(:set_fields_hash) ]
        end.to_h
        Heartbeat.where(id: updates.keys).update_all(fields_hash: updates)
      end
    end

    # delete duplicates
    Heartbeat.group(:fields_hash).having("count(*) > 1").count.each do |fields_hash, count|
      puts "Duplicate fields_hash: #{fields_hash} (count: #{count})"
      Heartbeat.where(fields_hash: fields_hash).order(:created_at).offset(1).delete_all
      puts "Deleted #{count - 1} heartbeat(s)"
    end
  end
end
