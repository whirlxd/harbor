class OneTime::GenerateUniqueHeartbeatHashesJob < ApplicationJob
  queue_as :default

  def perform
    Heartbeat.find_each do |heartbeat|
      heartbeat.send(:set_fields_hash!)
      heartbeat.save!
    end

    # error if any two heartbeats have the same fields_hash
    duplicates = false

    Heartbeat.group(:fields_hash).having("count(*) > 1").count.each do |fields_hash, count|
      puts "Duplicate fields_hash: #{fields_hash} (count: #{count})"
      duplicates = true
    end

    raise "Duplicate in fields_hash" if duplicates
  end
end
